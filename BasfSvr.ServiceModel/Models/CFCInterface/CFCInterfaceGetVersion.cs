using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ServiceStack;

namespace BasfSvr.ServiceModel
{
    [Route("/cfcgetversion", "GET")]
    public class CFCInterfaceGetVersionRequest : BaseRequest
    {
        public string LookupType { get; set; }
    }
    public class CFCInterfaceGetVersionResponse : BaseResponse
    {
        public string CFCVersionResponse { get; set; }
    }
}
