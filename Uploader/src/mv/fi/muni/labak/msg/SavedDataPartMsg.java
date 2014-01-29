package mv.fi.muni.labak.msg;

/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'SavedDataPartMsg'
 * message type.
 */

public class SavedDataPartMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 22;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 138;

    /** Create a new SavedDataPartMsg of size 22. */
    public SavedDataPartMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new SavedDataPartMsg of the given data_length. */
    public SavedDataPartMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SavedDataPartMsg with the given data_length
     * and base offset.
     */
    public SavedDataPartMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SavedDataPartMsg using the given byte array
     * as backing store.
     */
    public SavedDataPartMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SavedDataPartMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public SavedDataPartMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SavedDataPartMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public SavedDataPartMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SavedDataPartMsg embedded in the given message
     * at the given base offset.
     */
    public SavedDataPartMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SavedDataPartMsg embedded in the given message
     * at the given base offset and length.
     */
    public SavedDataPartMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <SavedDataPartMsg> \n";
      try {
        s += "  [len=0x"+Long.toHexString(get_len())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [key=0x"+Long.toHexString(get_key())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [data=";
        for (int i = 0; i < 20; i++) {
          s += "0x"+Long.toHexString(getElement_data(i) & 0xff)+" ";
        }
        s += "]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: len
    //   Field type: short, unsigned
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'len' is signed (false).
     */
    public static boolean isSigned_len() {
        return false;
    }

    /**
     * Return whether the field 'len' is an array (false).
     */
    public static boolean isArray_len() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'len'
     */
    public static int offset_len() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'len'
     */
    public static int offsetBits_len() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'len'
     */
    public short get_len() {
        return (short)getUIntBEElement(offsetBits_len(), 8);
    }

    /**
     * Set the value of the field 'len'
     */
    public void set_len(short value) {
        setUIntBEElement(offsetBits_len(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'len'
     */
    public static int size_len() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'len'
     */
    public static int sizeBits_len() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: key
    //   Field type: short, unsigned
    //   Offset (bits): 8
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'key' is signed (false).
     */
    public static boolean isSigned_key() {
        return false;
    }

    /**
     * Return whether the field 'key' is an array (false).
     */
    public static boolean isArray_key() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'key'
     */
    public static int offset_key() {
        return (8 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'key'
     */
    public static int offsetBits_key() {
        return 8;
    }

    /**
     * Return the value (as a short) of the field 'key'
     */
    public short get_key() {
        return (short)getUIntBEElement(offsetBits_key(), 8);
    }

    /**
     * Set the value of the field 'key'
     */
    public void set_key(short value) {
        setUIntBEElement(offsetBits_key(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'key'
     */
    public static int size_key() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'key'
     */
    public static int sizeBits_key() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: data
    //   Field type: short[], unsigned
    //   Offset (bits): 16
    //   Size of each element (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'data' is signed (false).
     */
    public static boolean isSigned_data() {
        return false;
    }

    /**
     * Return whether the field 'data' is an array (true).
     */
    public static boolean isArray_data() {
        return true;
    }

    /**
     * Return the offset (in bytes) of the field 'data'
     */
    public static int offset_data(int index1) {
        int offset = 16;
        if (index1 < 0 || index1 >= 20) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 8;
        return (offset / 8);
    }

    /**
     * Return the offset (in bits) of the field 'data'
     */
    public static int offsetBits_data(int index1) {
        int offset = 16;
        if (index1 < 0 || index1 >= 20) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 8;
        return offset;
    }

    /**
     * Return the entire array 'data' as a short[]
     */
    public short[] get_data() {
        short[] tmp = new short[20];
        for (int index0 = 0; index0 < numElements_data(0); index0++) {
            tmp[index0] = getElement_data(index0);
        }
        return tmp;
    }

    /**
     * Set the contents of the array 'data' from the given short[]
     */
    public void set_data(short[] value) {
        for (int index0 = 0; index0 < value.length; index0++) {
            setElement_data(index0, value[index0]);
        }
    }

    /**
     * Return an element (as a short) of the array 'data'
     */
    public short getElement_data(int index1) {
        return (short)getUIntBEElement(offsetBits_data(index1), 8);
    }

    /**
     * Set an element of the array 'data'
     */
    public void setElement_data(int index1, short value) {
        setUIntBEElement(offsetBits_data(index1), 8, value);
    }

    /**
     * Return the total size, in bytes, of the array 'data'
     */
    public static int totalSize_data() {
        return (160 / 8);
    }

    /**
     * Return the total size, in bits, of the array 'data'
     */
    public static int totalSizeBits_data() {
        return 160;
    }

    /**
     * Return the size, in bytes, of each element of the array 'data'
     */
    public static int elementSize_data() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of each element of the array 'data'
     */
    public static int elementSizeBits_data() {
        return 8;
    }

    /**
     * Return the number of dimensions in the array 'data'
     */
    public static int numDimensions_data() {
        return 1;
    }

    /**
     * Return the number of elements in the array 'data'
     */
    public static int numElements_data() {
        return 20;
    }

    /**
     * Return the number of elements in the array 'data'
     * for the given dimension.
     */
    public static int numElements_data(int dimension) {
      int array_dims[] = { 20,  };
        if (dimension < 0 || dimension >= 1) throw new ArrayIndexOutOfBoundsException();
        if (array_dims[dimension] == 0) throw new IllegalArgumentException("Array dimension "+dimension+" has unknown size");
        return array_dims[dimension];
    }

    /**
     * Fill in the array 'data' with a String
     */
    public void setString_data(String s) { 
         int len = s.length();
         int i;
         for (i = 0; i < len; i++) {
             setElement_data(i, (short)s.charAt(i));
         }
         setElement_data(i, (short)0); //null terminate
    }

    /**
     * Read the array 'data' as a String
     */
    public String getString_data() { 
         char carr[] = new char[Math.min(net.tinyos.message.Message.MAX_CONVERTED_STRING_LENGTH,20)];
         int i;
         for (i = 0; i < carr.length; i++) {
             if ((char)getElement_data(i) == (char)0) break;
             carr[i] = (char)getElement_data(i);
         }
         return new String(carr,0,i);
    }

}
