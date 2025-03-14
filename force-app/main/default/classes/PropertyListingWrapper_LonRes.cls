public class PropertyListingWrapper_LonRes {
    public property property{get;set;}
    public status status{get;set;}
    public pricing pricing{get;set;}
    public details details{get;set;}
    public commission commission{get;set;}
    public Decimal branch_code{get;set;}
    public media media{get;set;}
    public String id{get;set;}
    public class tenure{
        public DateTime expiry_date{get;set;}
        public String type{get;set;}
    }
    public class status{
        public String transaction_type{get;set;}
        public String instruction_date{get;set;}
        public String status{get;set;}
        public String available_date{get;set;}
        public Boolean hidden{get;set;}
        public String final_date{get;set;}
    }
    public class rooms{
        public Integer reception_rooms{get;set;}
        public Decimal bedrooms{get;set;}
        public Integer bathrooms{get;set;}
    }
    public class property{
        public Boolean new_home{get;set;}
        public String floor_level{get;set;}
        public String type{get;set;}
        public String floor_area{get;set;}
        public rooms rooms{get;set;}
        public features features{get;set;}
        public location location{get;set;}
        public tenure tenure{get;set;}
        public epc epc{get;set;}
    }
    public class pricing{
        public Integer final_price{get;set;}
        public String ground_rent{get;set;}
        public String rent_frequency{get;set;}
        public String service_charge{get;set;}
        public String price_qualifier{get;set;}
        public Integer asking_price{get;set;}
        public String council_tax_band{get;set;}
    }
    public class media{
        public list<String> photographs{get;set;}
        public String brochure{get;set;}
        public String floor_plan{get;set;}
        public String virtual_tour{get;set;}
        public String epc{get;set;}
    }
    public class location{
        public String postcode{get;set;}
        public String address_2{get;set;}
        public String city{get;set;}
        public String address_1{get;set;}
    }
    public class features{
        public Boolean outside_space{get;set;}
        public String furnished{get;set;}
        public Boolean lift{get;set;}
        public Boolean parking{get;set;}
    }
    public class epc{
        public eir eir{get;set;}
        public eer eer{get;set;}
    }
    public class eir{
        public Integer potential{get;set;}
        public Integer current{get;set;}
    }
    public class eer{
        public Integer potential{get;set;}
        public Integer current{get;set;}
    }
    public class details{
        public String description{get;set;}
        public String summary{get;set;}
    }
    public class commission{
        public String commission{get;set;}
        public String negotiator_bonus{get;set;}
    }
}