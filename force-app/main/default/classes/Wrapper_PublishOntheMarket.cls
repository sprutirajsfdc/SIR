public class Wrapper_PublishOntheMarket {
    
    public Network network;
    public Branch branch;
    public Property property;
    
    public class Network {
        public Integer network_id;
    }
    
    public class Branch {
        public Integer branch_id;
        public Integer channel;
        //    public Boolean overseas;
    }
    
    public class Address {
        public String house_name_number;
        
        public String address_2;
        public String address_3;
        public String address_4;
        
        public String town;
        public String postcode_1;
        public String postcode_2;
        public String display_address;
        /*
public Decimal latitude;
public Decimal longitude;
public Decimal pov_latitude;
public Decimal pov_longitude;
public Decimal pov_pitch;
public Decimal pov_heading;
public Integer pov_zoom;
*/
    }
    
    public class PriceInformation {
        public Decimal price;
        public Integer rent_frequency;
        public Integer tenure_type;
        public Integer tenure_unexpired_years;
    }
    
    public class Details {
        public String summary;
        public String description;
        public List<String> features;
        public Integer bedrooms;
        public Integer bathrooms;
        //     public Decimal internal_area;
        public Sizing sizing;
        /*
public List<Integer> parking;
public Integer year_built;
public Integer internal_area;
public Integer internal_area_unit;

public Integer floors;
public Integer entrance_floor;
public Integer condition;
public List<Integer> accessibility;
public List<Integer> heating;
public Integer furnished_type;
public Boolean business_for_sale;
public List<Integer> comm_use_class;
*/
    }
    
    public class Sizing {
        //    public Decimal minimum;
        public Decimal maximum;
        public Integer area_unit;
    }
    
    
    public class Media {
        public Integer media_type;
        public String media_url;
        public Integer sort_order;
        /*
public String caption;

public String media_update_date;
*/
    }
    
    public class Principal {
        public String principal_email_address;
        public Boolean auto_email_when_live;
        public Boolean auto_email_updates;
    }
    
    public class Property {
        public String agent_ref;
        public Boolean published;
        public Integer property_type;
        public Integer status;
        public Address address;
        public PriceInformation price_information;
        public Details details;
        public List<Media> media;
        /*
public String create_date;
public String update_date;
public String date_available;
public Integer contract_months;
public Integer minimum_term;
public Integer let_type;
public Principal principal;
*/
    }
    
    
}