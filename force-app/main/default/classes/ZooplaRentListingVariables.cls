public class ZooplaRentListingVariables {
  
    public class Local_authority {
public String council_tax_band;
}
    
    /*


public class Tenure {
public String type;
public Integer years_remaining;
public Shared_ownership shared_ownership;
}

*/
    /*
public class Ground_rent {
public Integer amount;
public Integer review_period;
public Integer percentage_increase;
}
*/
    // Location class
    public class Location {
        
        public String street_name;
        public String town_or_city;
        public String postal_code;
        public String country_code;
        //   public String county;
            public String property_number_or_name;
        
    }
    
// Areas class
public class Areas {
public Internal internal;
}

public class Internal {
public Minimum minimum;
public Maximum maximum;
}

// Inner classes
public class Minimum {
public Double value;
public String units;
}

public class Maximum {
public Double value;
public String units;
}

    /*

public class Shared_ownership {
public Integer percentage;
public String details;
}
*//*
    public class Area{
        public Double value;
        public String units;
    }
   */ 
    public class Content { //stores media - images
        public String url;
        public String type;
    }
    
    public class Detailed_description {
        public String text;
        public String heading;
        //  public Dimensions dimensions;
    }
    
    /* public class Dimensions {
public Double width;
public Double length;
public String units;
}*/
    
    public class Pricing {
        public String transaction_type;
        public String currency_code;
        public Integer price;
        public String rent_frequency;
        /*

public PricePerUnitArea price_per_unit_area;
public Boolean auction;
*/
    }
    /*
public class PricePerUnitArea {
public Double price;
public String units;
}
*/
    // Moved these properties to the end to ensure they can reference the classes defined above
    
    // Properties
    public String branch_reference;
    public String category;
    
    public List<Detailed_description> detailed_description;
    public String life_cycle_status;
    public String listing_reference;
    public Location location;
    public Pricing pricing;
    public String property_type;
    //    public List<String> accessibility;
      public Areas areas;
    public Integer bathrooms;
    //   public String central_heating;
    public List<Content> content;
    public List<String> feature_list;
    //  public List<String> commercial_use_classes;
    public String display_address;
    //  public Boolean double_glazing;
    //  public Integer floors;
    //   public Integer living_rooms;
    //  public Boolean new_home;
    //   public Boolean porter_security;
    public Integer total_bedrooms;
    //   public Boolean wood_floors;
    //    public List<String> bills_included;
    //    public Internal internal;
    public String furnished_state;
 //   public Area area;
    public Local_authority local_authority;
     public Boolean shared_accommodation;
   
}