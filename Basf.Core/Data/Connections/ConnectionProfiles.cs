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

        public static ConnectionProfile Get(string name)
        {
            // FUTURE: read this from disk?
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
