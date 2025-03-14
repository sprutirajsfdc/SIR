public class GetJsonToApex {
    public String status;
   	public String branch_reference;
    public List<Listings> listings;
    
    public class Listings {
        public String listing_etag;
      	public String listing_reference;
        public String url;
    }
    
	public String listing_reference;
	public String listing_etag;
	public String url;
	public Boolean new_listing;
    
    public static GetJsonToApex parse(String json) {
        return (GetJsonToApex) System.JSON.deserialize(json, GetJsonToApex.class);
    }
}