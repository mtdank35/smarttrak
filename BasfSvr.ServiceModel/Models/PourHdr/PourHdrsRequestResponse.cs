using System;
using ServiceStack;
using Basf.Data.Tables;
using System.Collections.Generic;

namespace BasfSvr.ServiceModel
{
    [Route("/pourhdrs", "GET")]
    public class PourHdrsRequest : BaseRequest
    {
    }

    public class PourHdrsResponse : BaseResponse
    {
        public List<PourHdr> PourHdrs { get; set; }
    }
}
