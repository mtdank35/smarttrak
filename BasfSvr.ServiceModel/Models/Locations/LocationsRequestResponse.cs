using System;
using ServiceStack;
using Basf.Data.Tables;
using System.Collections.Generic;

namespace BasfSvr.ServiceModel
{
    [Route("/locations", "GET")]
    public class LocationsRequest : BaseRequest
    {
    }

    public class LocationsResponse : BaseResponse
    {
        public List<Locations> Locations { get; set; }
    }
}
