using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BasfSvr.ServiceModel;
using BasfSvr.ServiceModel.Exceptions;
using ServiceStack;
using cfc.iccm;
using BASF.BaseModules;

namespace BasfSvr.ServiceInterface
{
    class CFCVersionInterface : Service
    {        
        public object Get(CFCInterfaceGetVersionRequest request)
        {            
            var response = new CFCInterfaceGetVersionResponse();
            var cfc = new CFC_Interface(@"C:\ProgramData\BASF\ICCM2\Settings.ini", "GL");
            

            switch(request.LookupType.ToUpperInvariant())
            {
                case "INTERFACE":
                    var interfaceVersion = cfc.getInterfaceVersion();
                    response.CFCVersionResponse = interfaceVersion;
                    break;
                case "DATABASE":
                    var dbVersion = cfc.getDBVersion();
                    response.CFCVersionResponse = dbVersion;
                    break;
                default:
                    throw new HttpError(System.Net.HttpStatusCode.NotAcceptable, "INVALID_LOOKUP_TYPE",
                            String.Format("LookupType '{0}' not valid.", request.LookupType));
                    
            }

           
            return response;
        }
    }
}
