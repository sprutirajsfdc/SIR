public class PropertyListingWrapper_Anywhere{
    public String expiresOn; 
    public String primaryMLS;
    public Double rent;	//40.73061
    public String rentalFrequencyDescription;	//Daily
    public String statusCode;	//AC //
    public String statusDescription;	//Active //
    public cls_propertyDetails propertyDetails;
    public cls_listingAgents[] listingAgents;
    public cls_office office;
    public Decimal listPrice;	//2500000//
    public String currencyCode;	//GBP//	
    public boolean isShowAddressOnInternet;//gh//
    public boolean isHideListPrice;//gh//
    public boolean isNewConstruction;//ghj//
    public boolean isShowOnInternet;// gh//
    public String providerIdentifier;	//85425411000 //
    public cls_media[] media;
    public cls_remarks[] remarks;
    public List<String> neighborhood { get; set; }
    public cls_websites[] websites;
    public cls_additionalDetails additionalDetails;
    
    public class cls_additionalDetails {
        public String expiresOn;	//2022-01-15T18:25:43.511Z
        //	public String withdrawnOn;	//2022-01-15T18:25:43.511Z
        //	public String closedOn;	//2022-01-15T18:25:43.511Z
        //	public cls_sellers sellers;
    }
    
    public	class cls_propertyDetails {
        public String typeCode;	//R //
        public String typeDescription;
        public cls_location location;
        public String propertyName;	//154 Laxmi complex//
        public Integer subtypeCode;
        public String subtypeDescription;
        public Decimal noOfBedrooms;
        public Decimal fullBath;
        public Decimal buildingArea;
        public String buildingAreaUnitCode;
        public String buildingAreaUnitDescription;
    }
    public class cls_location {
        public String district;	//Southern District of 12 Mar //<== comment
        public Double latitude;	//40.73061//
        public Double longitude;	//-73.935242//
        public String addressLine1;	//132, My Street//
        public String addressLine2;	//pqr//
        public String addressLine3;	//gfgh//
        public String city;	//New York//
        public String postalCode;	//12401//
        public String countryCode;	//GB//
        public String countryName;
    }
    public	class cls_listingAgents {
        public String companyStaffGuid;	//531c5fcb-4f73-4ab9-a78d-0a8b87af6123
        public cls_primaryOffice primaryOffice;
        public Integer sequenceNumber;	//1//
        public boolean isPrimary;// //
    }
    
    public	class cls_primaryOffice {
        public String officeGuid;	//65e03505-0342-4d15-a3bc-9b2fc5083046 //
        //     public String companyId;	//870126
        //      public String officeId;	//0001 
        //      public String providerIdentifier;	//5000000261
    }
    
    public class cls_office {
        public String officeGuid;	//65e03505-0342-4d15-a3bc-9b2fc5083046//
        
    }
    
    public class cls_media {
        public Integer sequenceNumber;	//1 //sort order
        public String category;	//Listing Photo
        public String url;	//http://commercial.century21.com/
        public String caption;	//Listing Photo //title
        public String description;	//string
        public String formatCode;	//UR
        
    }
    
    public class cls_remarks {
        public Integer remarkTypeCode;	//14
        public String remarkTypeDescription;	//Property Description
        public String languageCode;	//en
        public String languageName;	//English
        public String remark;	//remark about the open house
        public String htmlRemark;	//string
    }
    
    public class cls_websites {
        public String websiteTypeCode;	//BU
        //	public String websiteTypeDescription;	//ListingWebAddressType
        public String url;	//http://commercial.century21.com/
        public String contentLanguageCode;	//en
        public String contentLanguageName;	//English
        //	public String websiteName;	//http://commercial.century21.com/
        
    }
    
}