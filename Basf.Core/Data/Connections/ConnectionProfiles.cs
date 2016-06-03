using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace Basf
{
    public static class ConnectionProfiles
    {
        // FUTURE: Save
        // FUTURE: Get List
        // FUTURE: Delete

        public static string DefThing()
        {
            var db1 = "Data Source=.\\SQL_ICCM;Initial Catalog=CustDataNA;Integrated Security=False;User ID=sa;Password=rUnt94thigh=kAnE~Lover97Lid;Connect Timeout=5";
            var db2 = "Data Source=.\\SQL_ICCM;Initial Catalog=iccm_db;Integrated Security=False;User ID=sa;Password=rUnt94thigh=kAnE~Lover97Lid;Connect Timeout=5";
            var cp = new ConnectionProfile("DEFAULT", db1, db2);
            return JsonConvert.SerializeObject(cp, Formatting.Indented);
        }

        public static ConnectionProfile GetThing(string dbcs)
        {
            return JsonConvert.DeserializeObject<ConnectionProfile>(dbcs);
        }

        public static ConnectionProfile Get(string name)
        {
            // grab profile data from embedded resource
            var assembly = Assembly.GetExecutingAssembly();
            var resourceName = "Basf.Core.Data.Connections.DEFAULT-CP.json";

            using (Stream stream = assembly.GetManifestResourceStream(resourceName))
            using (StreamReader reader = new StreamReader(stream))
            {
                string json = reader.ReadToEnd();
                return JsonConvert.DeserializeObject<ConnectionProfile>(json);
            }
        }

    }
}
