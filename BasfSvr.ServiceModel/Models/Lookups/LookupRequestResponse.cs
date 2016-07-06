using System;
using ServiceStack;
using Basf.Data.Tables;
using System.Collections.Generic;

namespace BasfSvr.ServiceModel
{
    [Route("/lookup/{LookupType}", "GET")]
    public class LookupRequest : BaseRequest
    {
        public string LookupType { get; set; }
    }

    public class LookupResponse : BaseResponse
    {
        public List<Lookup> Values { get; set; }
    }

    public class Lookup
    {
        public string DbVal { get; set; }
        public string DisplayVal { get; set; }
    }
}
