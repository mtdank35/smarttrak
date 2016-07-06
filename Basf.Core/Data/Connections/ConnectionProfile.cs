using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Reflection;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace Basf
{
    public class ConnectionProfile
    {
        public string Name { get; set; }
        public string ConnectString { get; set; }
        public string IccmConnectString { get; set; }
        public string DataConnectString { get; set; }

        private Assembly entryAssembly = null;
        private SqlConnectionStringBuilder _custCb = null;
        private SqlConnectionStringBuilder _iccmCb = null;
        private SqlConnectionStringBuilder _dataCb = null;

        public ConnectionProfile(string name, string connectString, string iccmConnectString, string dataConnectString)
        {
            Name = name;
            ConnectString = connectString;
            IccmConnectString = iccmConnectString;
            DataConnectString = dataConnectString;

            _custCb = new SqlConnectionStringBuilder(connectString);
            _iccmCb = new SqlConnectionStringBuilder(iccmConnectString);
            _dataCb = new SqlConnectionStringBuilder(dataConnectString);
        }

        #region CustData*
        [JsonIgnore]
        public string CustDataServer
        {
            get
            {
                if (_custCb == null) return "";
                return _custCb.DataSource;
            }
        }

        [JsonIgnore]
        public string CustDataUser
        {
            get
            {
                if (_custCb == null) return "";
                return _custCb.UserID;
            }
        }

        [JsonIgnore]
        public string CustDataPassword
        {
            get
            {
                if (_custCb == null) return "";
                return _custCb.Password;
            }
        }

        [JsonIgnore]
        public string CustDataDbName
        {
            get
            {
                if (_custCb == null) return "";
                return _custCb.InitialCatalog;
            }
        }
        #endregion

        #region Iccm_db
        [JsonIgnore]
        public string IccmServer
        {
            get
            {
                if (_iccmCb == null) return "";
                return _iccmCb.DataSource;
            }
        }

        [JsonIgnore]
        public string IccmDatabase
        {
            get
            {
                if (_iccmCb == null) return "";
                return _iccmCb.InitialCatalog;
            }
        }

        [JsonIgnore]
        public string IccmUser
        {
            get
            {
                if (_iccmCb == null) return "";
                return _iccmCb.UserID;
            }
        }

        [JsonIgnore]
        public string IccmPassword
        {
            get
            {
                if (_iccmCb == null) return "";
                return _iccmCb.Password;
            }
        }
        #endregion

        #region Data*
        [JsonIgnore]
        public string DataServer
        {
            get
            {
                if (_dataCb == null) return "";
                return _dataCb.DataSource;
            }
        }

        [JsonIgnore]
        public string DataUser
        {
            get
            {
                if (_dataCb == null) return "";
                return _dataCb.UserID;
            }
        }

        [JsonIgnore]
        public string DataPassword
        {
            get
            {
                if (_dataCb == null) return "";
                return _dataCb.Password;
            }
        }

        [JsonIgnore]
        public string DataDbName
        {
            get
            {
                if (_dataCb == null) return "";
                return _dataCb.InitialCatalog;
            }
        }
        #endregion

        [JsonIgnore]
        public string ConnectStringWithAppInfo
        {
            get
            {
                return AddAppNameAndVersionToConnectString(ConnectString);
            }
        }

        [JsonIgnore]
        public string IccmConnectStringWithAppInfo
        {
            get
            {
                return AddAppNameAndVersionToConnectString(IccmConnectString);
            }
        }

        [JsonIgnore]
        public string DataConnectStringWithAppInfo
        {
            get
            {
                return AddAppNameAndVersionToConnectString(DataConnectString);
            }
        }

        private string AddAppNameAndVersionToConnectString(string dbcs)
        {
            if (entryAssembly == null)
                entryAssembly = System.Reflection.Assembly.GetEntryAssembly();

            if (entryAssembly == null)
                return dbcs;

            object productVersion = entryAssembly.GetName().Version.ToString();
            if (productVersion == null)
                return dbcs;

            return String.Format("{0};Application Name={1} {2};", dbcs, entryAssembly.GetName().Name, productVersion);
        }

        [OnSerializing]
        internal void OnSerializing(StreamingContext context)
        {
            // CustData* Db
            SqlConnectionStringBuilder scsb = new SqlConnectionStringBuilder(ConnectString);
            scsb.Password = Convert.ToBase64String(Encoding.UTF8.GetBytes(scsb.Password));
            ConnectString = scsb.ConnectionString;

            // Iccm Db
            scsb = new SqlConnectionStringBuilder(IccmConnectString);
            scsb.Password = Convert.ToBase64String(Encoding.UTF8.GetBytes(scsb.Password));
            IccmConnectString = scsb.ConnectionString;

            // Data* Db
            scsb = new SqlConnectionStringBuilder(DataConnectString);
            scsb.Password = Convert.ToBase64String(Encoding.UTF8.GetBytes(scsb.Password));
            DataConnectString = scsb.ConnectionString;
        }

        [OnSerialized]
        internal void OnSerialized(StreamingContext context)
        {
            // CustData* Db
            SqlConnectionStringBuilder scsb = new SqlConnectionStringBuilder(ConnectString);
            byte[] bytes = Convert.FromBase64String(scsb.Password);
            scsb.Password = Encoding.UTF8.GetString(bytes);
            ConnectString = scsb.ConnectionString;

            // Iccm Db
            scsb = new SqlConnectionStringBuilder(IccmConnectString);
            bytes = Convert.FromBase64String(scsb.Password);
            scsb.Password = Encoding.UTF8.GetString(bytes);
            IccmConnectString = scsb.ConnectionString;

            // Data* Db
            scsb = new SqlConnectionStringBuilder(DataConnectString);
            bytes = Convert.FromBase64String(scsb.Password);
            scsb.Password = Encoding.UTF8.GetString(bytes);
            DataConnectString = scsb.ConnectionString;
        }

        private string AddConnectTimeout(string dbcs)
        {
            if (!dbcs.Contains("Connection Timeout"))
                dbcs += ";Connection Timeout=5;";
            return dbcs;
        }

        [OnDeserializing]
        internal void OnDeserializing(StreamingContext context)
        {
            // CustData* Db
            _custCb = new SqlConnectionStringBuilder(ConnectString);
            byte[] bytes = Convert.FromBase64String(_custCb.Password);
            _custCb.Password = Encoding.UTF8.GetString(bytes);
            ConnectString = AddConnectTimeout(_custCb.ConnectionString);

            // Iccm Db
            _iccmCb = new SqlConnectionStringBuilder(IccmConnectString);
            bytes = Convert.FromBase64String(_iccmCb.Password);
            _iccmCb.Password = Encoding.UTF8.GetString(bytes);
            IccmConnectString = AddConnectTimeout(_iccmCb.ConnectionString);

            // Data* Db
            _dataCb = new SqlConnectionStringBuilder(DataConnectString);
            bytes = Convert.FromBase64String(_dataCb.Password);
            _dataCb.Password = Encoding.UTF8.GetString(bytes);
            DataConnectString = AddConnectTimeout(_dataCb.ConnectionString);
        }

        [OnDeserialized]
        internal void OnDeserialized(StreamingContext context)
        {
        }
    }
}
