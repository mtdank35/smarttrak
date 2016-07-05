using System;
using ServiceStack;
using Basf.Data.Tables;
using System.Collections.Generic;

namespace BasfSvr.ServiceModel
{
    [Route("/pourhdrs", "GET")]
    public class PourHdrRequest : BaseRequest
    {
    }

    public class PourHdrResponse : BaseResponse
    {
        public List<PourHdr> PourHdrs { get; set; }
    }
}
