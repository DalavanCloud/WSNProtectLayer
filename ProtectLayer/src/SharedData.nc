/**
 * Interface for aggregated storage of data for various modules in one place.
 * 
 * 	@version   1.0
 * 	@date      2012-2014
 */

#include "ProtectLayerGlobals.h"
interface SharedData {
	/**
	 * Easy access method to the entire structure of combinedData
	 * 
	 * @return a pointer to the combinedData structure
	 */
	command combinedData_t* getAllData();
	
	/**
	 * A shortcut method to the savedData structure
	 * 
	 * @return a pointer to the entire savedData of the combinedData structure
	 */
	command SavedData_t* getSavedData();
	
	/**
	 * A shortcut to savedData of a particular neighbor.
	 * 
	 * @param nodeId the id of requested neighboring node
	 * @return a pointer to the savedData of identified neighbor or NULL if such a neighbor is not stored
	 */
	command SavedData_t* getNodeState(uint16_t nodeId);
	
	/**
	 * A shortcut to the privacy module's private data.
	 * 
	 * @return a pointer to the privacy module's private data from the combinedData structure
	 */
	command PPCPrivData_t* getPPCPrivData();
	
	/**
	 * A shortcut to the routing module's private data.
	 * 
	 * @return a pointer to the routing module's private data from the combinedData structure
	 */
	command RoutePrivData_t* getRPrivData();
	
	/**
	 * A shortcut to the key distribution module's private data.
	 * 
	 * @return a pointer to the key distribution module's private data from the combinedData structure
	 */
	command KDCPrivData_t* getKDCPrivData();
	
	/**
	 * A shortcut to the predistributed keys.
	 * @param nodeId id of node
	 * @return a handle to predistributed key for node.
	 */
	command error_t getPredistributedKeyForNode(uint16_t nodeId, PL_key_t* predistribKey);
}
