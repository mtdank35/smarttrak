using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BasfCli.Conf
{
    public class GlobalConf
    {
        public string ConnectString { get; set; }
        public string OutputDir { get; set; }

        [JsonIgnoreAttribute]
        private SqlConnectionStringBuilder _custDataCb = null;

        public GlobalConf()
        {
            ConnectString = @"Data Source=.\SQL_ICCM;Initial Catalog=iccm_db;Integrated Security=False;User ID=sa;Password=123;Connect Timeout=5";
            OutputDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "BasfCli");
            _custDataCb = new SqlConnectionStringBuilder(ConnectString);
        }
    }
}
