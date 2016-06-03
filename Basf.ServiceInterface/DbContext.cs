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

        public DbContext(ConnectionProfile cp)
        {
            _cp = cp;
            _custDbi = NewCustDbInstance();
            _iccmDbi = NewIccmDbInstance();
        }

        public CustDataDbi NewCustDbInstance()
        {
            return new CustDataDbi(_cp.ConnectStringWithAppInfo);
        }

        public IccmDbi NewIccmDbInstance()
        {
            return new IccmDbi(_cp.IccmConnectStringWithAppInfo);
        }

        public string CustDbcs { get { return _cp.ConnectStringWithAppInfo; } }

        public string IccmDbcs { get { return _cp.IccmConnectStringWithAppInfo; } }
    }
}
