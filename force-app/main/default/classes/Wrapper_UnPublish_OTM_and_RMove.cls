public class Wrapper_UnPublish_OTM_and_RMove{
    public Network network;
    public Branch branch;
    public Property property;
    public class Network {
        public Integer network_id;	//987
    }
    public class Branch {
        public Integer branch_id;	//12345
        public Integer channel;	//1
    }
    public class Property {
        public String agent_ref;	//testproperty1
        public Integer removal_reason; 	//7
        public String transaction_date;	//01-03-2017 10:00:00 //for now : date of unpublish request
    }
    
}