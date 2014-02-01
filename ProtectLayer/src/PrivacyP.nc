/**
 * The implementation of privacy component. It is abstracted by configuration PrivacyC.
 * 
 * 	@version   0.1
 * 	@date      2012-2013
 * 
 **/

#include "ProtectLayerGlobals.h"

module PrivacyP {
    uses {
        interface AMSend as LowerAMSend;
        interface Receive as LowerReceive;
        interface Packet;
        interface AMPacket;
        interface SplitControl as AMControl;
        interface IntrusionDetect;
        interface Init as IntrusionDetectInit; 
        interface Route;
        interface PrivacyLevel;
        interface SharedData;
        interface KeyDistrib;
        interface Crypto;
        interface Logger;
        interface Dispatcher;
        
        interface Timer<TMilli> as RetxmitTimer;
        interface Random;
    }
    
    provides {
        interface Init;
        interface Init as PLInit;
        interface Privacy;
        
        // parameterized interfaces for different message types
        interface AMSend as MessageSend[uint8_t id];	 
        interface Receive as MessageReceive[uint8_t id];
        interface SplitControl as MessageAMControl;
        //interface AMPacket as MessageAMPacket;	// TODO: implement
        interface Packet as MessagePacket;
    }	
}
implementation {
    PPCPrivData_t * m_privData = NULL;
    uint8_t reputation;
    bool m_radioBusy = FALSE;
    message_t* m_lastMsg = NULL;
    uint8_t m_lastMsgSender = 0;
    SPHeader_t* m_spHeader=NULL;
    SendRequest_t m_buffer[MSG_COUNT];
    uint8_t m_nextId=0;
    message_t* m_canceledMsg = NULL;
    // receive buffer
    message_t m_receiveMemoryBuffer[RECEIVE_BUFFER_LEN];
    RecMsg_t m_receiveBuffer[RECEIVE_BUFFER_LEN];
    uint8_t m_recNextToProcess=0;
    uint8_t m_recNextToStore=0;
    // msgs for  IDS copy
    message_t m_msgMemoryForIDS;
    RecMsg_t m_msgForIDS;
    static const char *TAG = "PrivacyP";
    
    
    static void startRetxmitTimer(uint16_t mask, uint16_t offset);
    
    //
    //	Init interface
    //
    command error_t Init.init() {
        
        uint8_t i=0;
        
        //init receive buffer
        for(i = 0; i < RECEIVE_BUFFER_LEN; i++)
        {
            m_receiveBuffer[i].msg = &m_receiveMemoryBuffer[i];
            m_receiveBuffer[i].isEmpty=1;
        }
        
        //init IDS copy msg
        m_msgForIDS.msg = &m_msgMemoryForIDS;
        
        dbg("NodeState", "Privacy component initialization...\n");
        
        return SUCCESS;
    }
    
    command error_t PLInit.init() {
        
        m_privData = call SharedData.getPPCPrivData();
        // TODO PL setting probably here?
        m_privData->priv_level = PLEVEL_0;
        return SUCCESS;
    }
    
    //
    //	Privacy interface
    //
    command PRIVACY_LEVEL Privacy.getCurrentPrivacyLevel(){	
        dbg("Privacy","Privacy: PrivacyP.Privacy.getCurerentPrivacyLevel, %d\n",m_privData->priv_level);
        return m_privData->priv_level;
    }
    
    
    //
    // PrivacyLevel interface
    //
    event void PrivacyLevel.privacyLevelChanged(error_t status, PRIVACY_LEVEL newPrivacyLevel){
        //TODO: check for allowed priv levels
        if (status == SUCCESS) {
            m_privData->priv_level = newPrivacyLevel;	
            dbg("Privacy","Privacy: PrivacyP.PrivacyLevel.privacyLevelChanged, %d\n",m_privData->priv_level);
        }
    }
    
    
    void passToIDS(message_t* msg, void* payload, uint8_t len)
    {
        // copy message content to IDS msg
        if (msg==NULL || payload==NULL){
        	pl_log(PL_LOG_ERROR, TAG, "pass2IDS ERR null\n");
        	return;
        }
        
        //memcpy(m_msgForIDS.msg,msg,sizeof(message_t));
        //m_msgForIDS.payload = call Packet.getPayload(m_msgForIDS.msg, len);
        //m_msgForIDS.len = len;
        
        // signal to IDS and update memory field for next msg
        //m_msgForIDS.msg = signal MessageReceive.receive[MSG_IDSCOPY](m_msgForIDS.msg, m_msgForIDS.payload, m_msgForIDS.len);
        
    }
    
    
    //
    // Receive interface - LowerReceive
    //
    task void task_receiveMessage() {
        
        message_t* retMsg = NULL;
        message_t* msg = NULL;
        uint8_t len = 0;
        void* payload = NULL;
        SPHeader_t* ourHeader = NULL;
        //PL_key_t * key; encrypt has nodeID parameter, key is not required
        uint8_t decLen = 0;
        error_t status = SUCCESS;
        
        // Get msg to be processed , TODO we could check if isEmpty, but it never should be emtpy
		msg = m_receiveBuffer[m_recNextToProcess].msg;
		
		if (m_receiveBuffer[m_recNextToProcess].isEmpty){
        	pl_log(PL_LOG_ERROR, TAG, "task_receiveMessage IS EMPTY!\n");
        }
        if (msg==NULL){
        	pl_log(PL_LOG_ERROR, TAG, "task_receiveMessage IS NULL!\n");	
        }
        
        // Get our header from payload
        ourHeader = (SPHeader_t*) m_receiveBuffer[m_recNextToProcess].payload;

        pl_printf("Privacy: task_receiveMessage 2, buffer position %d\n", (int)m_recNextToProcess); 
        
        switch (ourHeader->privacyLevel) {
        case PLEVEL_0: {
            // check if I am receiver of the message
            if (ourHeader->receiver == TOS_NODE_ID)
            {
                //decrypt
                decLen= m_receiveBuffer[m_recNextToProcess].len - sizeof(SPHeader_t);                                
                status = call Crypto.unprotectBufferFromNodeB(ourHeader->sender, (uint8_t*) ourHeader, sizeof(SPHeader_t), &decLen);
                
                pl_printf("Privacy: task_receiveMessage 3, ourHeader->receiver == TOS_NODE_ID, status=%d l=%u ln=%u\n", status, m_receiveBuffer[m_recNextToProcess].len, decLen); 
                
                m_receiveBuffer[m_recNextToProcess].len = decLen + sizeof(SPHeader_t);

                // msg is for me
                // check MSG_TYPE
                if (ourHeader->msgType == MSG_APP)
                {

                	pl_printf("Privacy: task_receiveMessage 4, ourHeader->msgType == MSG_APP\n"); 

                    //copy msg and pass to IDS
                    passToIDS(msg, m_receiveBuffer[m_recNextToProcess].payload, m_receiveBuffer[m_recNextToProcess].len);
                    //signal event to forwarder, this is special case since APP messages are forwarded to the BS and not to the app level
                    retMsg = signal MessageReceive.receive[MSG_FORWARD](msg, m_receiveBuffer[m_recNextToProcess].payload, m_receiveBuffer[m_recNextToProcess].len);	
                }
                else
                {

                        pl_printf("Privacy: task_receiveMessage 4, ourHeader->msgType != MSG_APP\n"); 

                    // other type of msg, remove protections if any,
                    //TODO
                    //copy msg and pass to IDS
                    passToIDS(msg, m_receiveBuffer[m_recNextToProcess].payload, m_receiveBuffer[m_recNextToProcess].len);
                    
                    // Payload is now including our header. Stripe our header and provide offseted pointer and decrease payload length	
                    len = m_receiveBuffer[m_recNextToProcess].len - sizeof(SPHeader_t);
                    payload = m_receiveBuffer[m_recNextToProcess].payload + sizeof(SPHeader_t);
                    
                    // Simple test of connection IDS providing reputation for TOSSIM
                    //reputation = call IntrusionDetect.getNodeReputation(1);
                    //dbg("NodeState", "Reputation is: %d.\n", reputation);

                    pl_printf("Privacy: PrivacyP.LowerReceive.receive, MSG type %x.\n", ourHeader->msgType); 

                    //TODO: test if our message
                    retMsg = signal MessageReceive.receive[ourHeader->msgType](msg, payload, len);
                }					
            }
            else
            {

                    pl_printf("Privacy: task_receiveMessage 3, ourHeader->receiver != TOS_NODE_ID\n"); 

                // It is not for me, pass copy to IDS
                passToIDS(msg, m_receiveBuffer[m_recNextToProcess].payload, m_receiveBuffer[m_recNextToProcess].len);
                retMsg = msg;
            }
            
            break;
        }
        case PLEVEL_1: {
            
            break;
        }
        case PLEVEL_2: {
            
            break;
        }
        default: 
            // privacy level not recognized, TODO pass copy of msg to IDS ?
            retMsg = msg;
        }
        
        // empty message_t slot, update which slot to process next and end task
        atomic {
        m_receiveBuffer[m_recNextToProcess].msg = retMsg;
        m_receiveBuffer[m_recNextToProcess].isEmpty=1;
        m_recNextToProcess = (m_recNextToProcess+1)%RECEIVE_BUFFER_LEN;
        }
        
        return;	
    }	
    
    /**
     * Message received from the lower AM interface.
     * Message is stored to the buffer if there is space for it.
     */
    event message_t* LowerReceive.receive(message_t* msg, void* payload, uint8_t len) {
        
        message_t * tmpMsg = NULL;
        
        //get new message_t to be returned
        if (m_receiveBuffer[m_recNextToStore].isEmpty)
        {
        	atomic{
            tmpMsg = m_receiveBuffer[m_recNextToStore].msg; 
            m_receiveBuffer[m_recNextToStore].msg = msg;
            m_receiveBuffer[m_recNextToStore].payload = payload;
            m_receiveBuffer[m_recNextToStore].len = len;
            m_receiveBuffer[m_recNextToStore].isEmpty = 0;
            m_recNextToStore = (m_recNextToStore+1)%RECEIVE_BUFFER_LEN; // update pointer to next position to which next msg will be stored
            }
            
            pl_printf("Privacy: PrivacyP 1 LowerREceive.receive, buffer #%u,p=%p\n", m_recNextToStore, msg);//  
        }
        else
        {
            //buffer full, return original message without modification
            return msg;
        }        

        post task_receiveMessage();        
        return tmpMsg;
    } 
    
    
    
    
    
    //
    //	AMSend[uint8_t id] interface
    //
    error_t sendMsgApp(SendRequest_t* sReq)
    {
        //behavior switch based on current privacy level
        switch (m_privData->priv_level) {
        case PLEVEL_0: {
            //do nothing special
            break;
        }
        case PLEVEL_1: {
            sReq->addr = AM_BROADCAST_ADDR;
            break;
        }
        case PLEVEL_2: {
            
            break;
        }
        default: 
            return FAIL;
        }
        return SUCCESS;
    }
    
    task void task_sendMessage(){	
        
        SPHeader_t* spHeader = NULL;
        error_t rval=SUCCESS;
        SendRequest_t sReq; 
        uint8_t count=0;
        //PL_key_t* key; encrypt has parameter nodeID, key it not required
        uint8_t encLen;
        
        // check if radio is busy or not
        if (m_radioBusy){
        	if (!call RetxmitTimer.isRunning()) {
        		// If retransmit timer is not running, start it with
        		// a randomized value. It will trigger this task again.
        		startRetxmitTimer(SENDDONE_FAIL_WINDOW, SENDDONE_FAIL_OFFSET);
        	}
        	
            return;
        }
        
        //find next message to send in buffer
        while(m_buffer[m_nextId].msg==NULL && count<MSG_COUNT)
        {
            m_nextId=(m_nextId+1)%MSG_COUNT;
            count++;
        }
        if (count==MSG_COUNT) {
            dbg("Privacy","Privacy: PrivacyP.task_sendMessage, nothing in the buffer\n");
            return; //no message to send, buffer is empty
        }
        if (m_buffer[m_nextId].msg==NULL){
        	pl_printf("PrivacyP: ERR, nullMsg\n");
        }
        
        atomic {
        //get info SendRequest from m_buffer
        sReq.addr = m_buffer[m_nextId].addr;
        sReq.msg = m_buffer[m_nextId].msg;
        sReq.len = m_buffer[m_nextId].len;
        
        // store msg pointer for further check in sendDone	
        m_lastMsg = sReq.msg;
        m_lastMsgSender = m_nextId;
        }
        
        //check who is sending msg, if forwarding only, treat it differently
        if (m_nextId == MSG_FORWARD)
        {
            //only forwarding packet, SPHeader already present, just change receiver and sender field
            //get spHeader
            spHeader =  (SPHeader_t *) call Packet.getPayload(sReq.msg, sReq.len);
            //process sender and receiver and msg type based on privacy level
            if (spHeader->privacyLevel==PLEVEL_0)
            {
                //find out who is next hop
                spHeader->receiver = call Route.getParentID(); //TODO take care of a case if ID is not valid
                // add myself as a sender
                spHeader->sender = TOS_NODE_ID;
                // leave privacy type and msg type as is
            }
            else
            {
                //TODO
            }
        }
        else
        {
            // Include SP header
            //TODO add payload len check
            sReq.len += sizeof(SPHeader_t);
            
            spHeader =  (SPHeader_t *) call Packet.getPayload(sReq.msg, sReq.len);
            // Setting info into our header
            spHeader->msgType = m_nextId; 
            spHeader->privacyLevel = m_privData->priv_level;
            //find out who is next hop
            spHeader->receiver = call Route.getParentID(); //TODO take care of a case if ID is not valid
            // add myself as a sender
            spHeader->sender = TOS_NODE_ID;
        }
        
        //pl_printf("PrivacyP: task_messageSend, offset %d .\n", sizeof(SPHeader_t)); 
        
        
        //encryption
        encLen=sReq.len - sizeof(SPHeader_t);
        //key = call KeyDistrib.getKeyToNodeB(spHeader->receiver);
        rval = call Crypto.protectBufferForNodeB(spHeader->receiver, (uint8_t *)spHeader, sizeof(SPHeader_t), &encLen);
        sReq.len = encLen + sizeof(SPHeader_t);
        
        
        //behavior switch based on interface parameter (id) 
        switch (m_nextId) {
        case (MSG_APP): {
            
            sendMsgApp(&sReq);
            break;
        }
        case (MSG_PLEVEL):{
            // do nothing special, no matter the actual privacy level 
            
            break;
        }
        case (MSG_FORWARD):{
            // do nothing special, no matter the actual privacy level 
            
            break;
        }
        default: {
            // do nothing special
        }
        }
        dbg("Privacy","Privacy: PrivacyP.task_messageSend, sending MSG type %d\n",m_nextId);
        
        rval = call LowerAMSend.send(sReq.addr,sReq.msg,sReq.len);
        if(rval == SUCCESS) {
            // Sent successfully, clear buffer and increase id.
            atomic {
            m_buffer[m_nextId].addr = 0;
            m_buffer[m_nextId].msg = NULL;
            m_buffer[m_nextId].len = 0;
            m_nextId = (m_nextId+1)%MSG_COUNT;
            m_radioBusy=TRUE;
            }
            
            pl_printf("privacyP: sendtask, lowSend=%p c=%d ln=%d\n", sReq.msg, m_lastMsgSender, sReq.len);
            
        } else {
        	if (!call RetxmitTimer.isRunning()) {
        		startRetxmitTimer(SENDDONE_FAIL_WINDOW, SENDDONE_FAIL_OFFSET);
        	}
        	
        	pl_printf("privacyP: sendtask, lowSend fail=%p, code=%d\n", sReq.msg, rval);
        }
        
        return;
    }
    
    
    command error_t MessageSend.send[uint8_t id](am_addr_t addr, message_t* msg, uint8_t len) {        
        // check if Id is within bounds
        if (id>=MSG_COUNT)
            return FAIL;
        
        // check if radio is busy for this id
        if (m_buffer[id].msg!=NULL) {
            //dbg("Privacy","Privacy: PrivacyP.MessageSend.send, buffer for id %d is full\n",id);
            return EBUSY;
        }
        //dbg("Privacy","Privacy: PrivacyP.MessageSend.send, adding msg of type %d\n",id);
        // put message into buffer
        atomic{
        m_buffer[id].addr = addr;
        m_buffer[id].msg = msg;
        m_buffer[id].len = len;
        }
                
        // is the radio busy?
        if (!m_radioBusy){
            post task_sendMessage();
        } else { 
        	startRetxmitTimer(SENDDONE_FAIL_WINDOW, SENDDONE_FAIL_OFFSET);
        }
        
        return SUCCESS;
    }
    
    static void startRetxmitTimer(uint16_t window, uint16_t offset) {                                                                                                      
	    uint16_t r = call Random.rand16();
	    r %= window;
	    r += offset;
	    call RetxmitTimer.startOneShot(r);
    }
    
    event void RetxmitTimer.fired() {                                                                                                                                      
	    post task_sendMessage();
    }
    
    
    command error_t MessageSend.cancel[uint8_t id](message_t* msg) {
        return FAIL; 
        
        /*
        //if message still in buffer
        if (m_buffer[id].msg == msg)
        {
            m_buffer[id].addr = 0;
            m_buffer[id].msg = NULL;
            m_buffer[id].len = 0;
            m_canceledMsg = msg;
            post task_sendCanceled()
            return SUCCESS;		
        }
        
        //otherwise
        return call LowerAMSend.cancel(msg);
        */
    }
    command uint8_t MessageSend.maxPayloadLength[uint8_t]() {
        // We will reserve some length for our header
        return (uint8_t) (call LowerAMSend.maxPayloadLength() - sizeof(SPHeader_t));
    }
    command void* MessageSend.getPayload[uint8_t](message_t* msg, uint8_t len) {
        // Get payload
        void* tmp = call LowerAMSend.getPayload(msg, (uint8_t) (len + sizeof(SPHeader_t)));
        // Return payload offset after our header
        return tmp + sizeof(SPHeader_t);
    }
    default event void MessageSend.sendDone[uint8_t](message_t* msg, error_t error) {}
    
    //
    // MessageReceive
    //
    default event message_t* MessageReceive.receive[uint8_t id](message_t* msg, void* payload, uint8_t len) { 		
    return msg; 
} 
    //
    //	LowerAMSend interface
    //
    event void LowerAMSend.sendDone(message_t* msg, error_t error) {
    //test if our message was sent
    if (m_lastMsg != msg)
    return;
    
    // radio not busy, schedule sending task.
    m_radioBusy = FALSE;
    startRetxmitTimer(SENDDONE_OK_WINDOW, SENDDONE_OK_OFFSET);
    
    pl_printf("privacyP: sendtask, lowSendDone, p=%p c=%d code=%d\n", msg, m_lastMsgSender, error);
    dbg("Privacy","Privacy: PrivacyP.LowerAMSend.sendDone, radio not busy from now\n");
    
    // Signal to particular interface 
    signal MessageSend.sendDone[m_lastMsgSender](msg, error);
}

	//
	// Radio & ProtectLayer initialization
	//

    void radioStartDone(error_t err);
    task void radioStart(){
    	error_t err = call AMControl.start();
    	
    	// The returned value can be also EALREADY in which
    	// case startDone is not called, so in order to prevent
    	// being stuck here call it manually.
    	if (err!=SUCCESS){
    		radioStartDone(err);
    	}
    }
    
    task void radioStarted(){
    	pl_printf("PrivacyP: radio started.");
    	call Dispatcher.serveState();
    }
    
    void radioStartDone(error_t err){
    	if (err == SUCCESS || err==EALREADY) {
    		// Radio was started successfully or was already started.
    		// In both cases proceed to PL initialization in
    		// a Dispatcher. This is done in a task
    		// since initialization can take a long time.
		    post radioStarted();
		    
		} else {
			// Starting the radio was not successful.
			// Try it again in  
			post radioStart();
		}
    }
    
    command void Privacy.startApp(error_t err) {
        // Dispatcher has everything initialized right now.
		pl_printf("PrivacyP: Going to signal message AMControl.startDone()\n");
		signal MessageAMControl.startDone(err);
    }
    
    //
    // AMControl interface
    //
    event void AMControl.startDone(error_t err) {
	    radioStartDone(err);
    }
    	
    event void AMControl.stopDone(error_t err) {
        // do nothing
    }	
    
    //
    // MessageAMControl (aka SplitPhase) interface
    //	
    command error_t MessageAMControl.start() {
    pl_printf("NodeState: <MessageAMControl>\n"); 
	
	// For real operation, radio has to be started at first
	// due to routing, key establishment, etc...
	// Radio start is done in task, until start is successful.
	post radioStart();
    return SUCCESS;	
}
    command error_t MessageAMControl.stop() {
    return SUCCESS;	
}
    default event void MessageAMControl.startDone(error_t err) {} 
    
    //
    //	MessagePacket
    //	
    command void MessagePacket.clear(message_t* msg) {
    call Packet.clear(msg);
}
    command uint8_t MessagePacket.payloadLength(message_t* msg) {
    //TODO return value depending on privacy level 
    return (uint8_t) (call Packet.payloadLength(msg) - sizeof(SPHeader_t));
}
    command void MessagePacket.setPayloadLength(message_t* msg, uint8_t len) {
    call Packet.setPayloadLength(msg, (uint8_t)(len + sizeof(SPHeader_t)));
}
    command uint8_t MessagePacket.maxPayloadLength() {
    //TODO return value depending on privacy level 
    return (uint8_t)(call Packet.maxPayloadLength() - sizeof(SPHeader_t));
}
    command void* MessagePacket.getPayload(message_t* msg, uint8_t len) {
    // Get payload
    void* tmp = call Packet.getPayload(msg, (uint8_t) (len + sizeof(SPHeader_t)));
    // Return payload offset after our header
    return tmp + sizeof(SPHeader_t);
}
    
    //
    // Route
    //
    event void Route.randomNeighborIDprovided(error_t status, node_id_t id){
    // do nothing
}	
    event void Route.randomParentIDprovided(error_t status, node_id_t id){
    // do nothing
}
    
    /*
    //
    // KeyDistrib
    //
    event void KeyDistrib.getKeyToBSDone(error_t result, PL_key_t *pBSKey){
        // TODO Auto-generated method stub
    }
    
    event void KeyDistrib.discoverKeysDone(error_t result){
        // TODO Auto-generated method stub
    }
    
    event void KeyDistrib.getKeyToNodeDone(error_t result, PL_key_t *pNodeKey){
        // TODO Auto-generated method stub
    }
    */
    /*
    //
    // Crypto
    //
    event void Crypto.decryptBufferDone(error_t status, uint8_t *buffer, uint8_t resultLen){
        // TODO Auto-generated method stub
    }
    
    event void Crypto.deriveKeyDone(error_t status, PL_key_t *derivedKey){
        // TODO Auto-generated method stub
    }
    
    event void Crypto.generateKeyDone(error_t status, PL_key_t *newKey){
        // TODO Auto-generated method stub
    }
    
    event void Crypto.encryptBufferDone(error_t status, uint8_t *buffer, uint8_t resultLen){
        // TODO Auto-generated method stub
    }
*/
    //
    // interface Logger
    //
    event void Logger.logToPCDone(message_t *msg, error_t error){
    // TODO Auto-generated method stub
}
} 
    
    
    