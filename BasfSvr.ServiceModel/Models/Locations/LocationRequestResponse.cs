using System;
using ServiceStack;
using Basf.Data.Tables;
using System.Collections.Generic;

namespace BasfSvr.ServiceModel
{
    [Route("/location/{LocId}", "GET,PUT,POST,DELETE")]
    public class LocationRequest : BaseRequest
    {
        public int LocId { get; set; }
        public Locations Loc { get; set; }
    }

    public class LocationResponse : BaseResponse
    {
        public Locations Location { get; set; }
    }
}
