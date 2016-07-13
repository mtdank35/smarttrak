using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ServiceStack;
using Basf.Data.Tables;

namespace BasfSvr.ServiceModel
{
    [Route("/cfcgetsscan", "GET")]
    public class CFCSScanRequest : BaseRequest
    {
        //public string id { get; set; }
    }
    public class CFCSScanResponse : BaseResponse
    {
        //public string SScanResponse { get; set; }
        public List<JobHeader> jobHdrs { get; set; }
    }
}
