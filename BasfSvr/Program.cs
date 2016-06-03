using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

namespace BasfSvr
{
    static class Program
    {
        private static readonly NLog.Logger _logger = NLog.LogManager.GetCurrentClassLogger();

        private const string SERVICE_CONTROLLER_NAME = "BasfSvr";

        static void Main(string[] args)
        {
            try
            {
                BasfSvrService impl = new BasfSvrService();
                if (args.Length == 0 && !Environment.UserInteractive)
                    ServiceBase.Run(new ServiceBase[] { impl });
                else
                {
                    var helper = new Basf.Console.Services.InteractiveServiceHelper(SERVICE_CONTROLLER_NAME, impl);
                    helper.ProcessCommandLine<Basf.Console.Services.Args.CmdSvcArgs>(args);
                }
            }
            catch (Exception ex)
            {
                _logger.ErrorException("Startup error", ex);
            }
        }
    }
}
