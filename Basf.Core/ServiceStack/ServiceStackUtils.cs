using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf
{
    public class ServiceStackUtils
    {
        public static void Configure()
        {
            ConfigureLicense();
            ConfigureDefaults();
        }

        private static void ConfigureDefaults()
        {
            //Set JSON web services to return idiomatic JSON camelCase properties
            ServiceStack.Text.JsConfig.EmitCamelCaseNames = true;

            // return dates like this: 2012-08-21T11:02:32.0449348-04:00
            ServiceStack.Text.JsConfig.DateHandler = ServiceStack.Text.DateHandler.ISO8601;
        }

        private static void ConfigureLicense()
        {
            // FUTURE: Buy a license
//            string licKey =
//@"
//";
//            ServiceStack.Licensing.RegisterLicense(licKey);
        }
    }
}
