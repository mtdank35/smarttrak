using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ServiceStack;
using System.Data.SqlClient;
using BasfSvr.ServiceModel;
using Humanizer;
using cfc.iccm;

namespace BasfSvr.ServiceInterface
{
    public class CFCSScanInterface : Service
    {
        public DbContext DbContext { get; set; }

        public object Get(CFCSScanRequest request)
        {           
            using (var dbi = DbContext.NewSScanDbInstance())
            {                
                var things = dbi.JobHeader.GetList(null);                
                var response = new CFCSScanResponse();
                response.jobHdrs = things.ToList();
                return response;
            }            
        }
    }
}
