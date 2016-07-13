using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Basf;
using Basf.Data;

namespace BasfSvr.ServiceInterface
{
    public class DbContext
    {
        private ConnectionProfile _cp = null;
        private static NLog.Logger _log = NLog.LogManager.GetCurrentClassLogger();

        private CustDataDbi _custDbi = null;
        public CustDataDbi CustDbi
        {
            get
            {
                return _custDbi;
            }
        }

        private IccmDbi _iccmDbi = null;
        public IccmDbi IccmDbi
        {
            get
            {
                return _iccmDbi;
            }
        }

        private DataDbi _dataDbi = null;
        public DataDbi DataDbi
        {
            get
            {
                return _dataDbi;
            }
        }

        private SSCanDataDbi _sscanDbi = null;
        public SSCanDataDbi SScanDataDbi
        {
            get
            {
                return _sscanDbi;
            }
        }

        public DbContext(ConnectionProfile cp)
        {
            _cp = cp;
            _custDbi = NewCustDbInstance();
            _iccmDbi = NewIccmDbInstance();
            _dataDbi = NewDataDbInstance();
            _sscanDbi = NewSScanDbInstance();
        }

        public CustDataDbi NewCustDbInstance()
        {
            return new CustDataDbi(_cp.ConnectStringWithAppInfo);
        }

        public IccmDbi NewIccmDbInstance()
        {
            return new IccmDbi(_cp.IccmConnectStringWithAppInfo);
        }

        public DataDbi NewDataDbInstance()
        {
            return new DataDbi(_cp.DataConnectStringWithAppInfo);
        }

        public SSCanDataDbi NewSScanDbInstance()
        {
            return new SSCanDataDbi(_cp.SScanConnectString);
        }

        public string CustDbcs { get { return _cp.ConnectStringWithAppInfo; } }

        public string IccmDbcs { get { return _cp.IccmConnectStringWithAppInfo; } }

        public string DataDbcs { get { return _cp.DataConnectStringWithAppInfo; } }

        public string SScanDbcs { get { return _cp.SScanConnectString; } }
    }
}
