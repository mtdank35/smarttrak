using System;
using System.ServiceProcess;
using Basf.Console.Services;
using System.Threading;
using ServiceStack.Logging;
using System.Configuration;

namespace BasfSvr
{
    public partial class BasfSvrService : ServiceBase, IWindowsService
    {
        private static NLog.Logger _logger = NLog.LogManager.GetCurrentClassLogger();
        private Thread _serviceThread;
        private bool _stopRequested;

        public bool RunOnce { get; set; }
        public bool Foreground { get; set; }
        public string[] Args { get; set; }
        public BasfSvrService()
        {
            InitializeComponent();
            LogManager.LogFactory = new ServiceStack.Logging.NLogger.NLogFactory();
        }

        protected override void OnStart(string[] args)
        {
            try
            {
                _logger.Info("start requested");
                Args = args;
                _serviceThread = new Thread(ProcessLoop);
                _serviceThread.Start();
            }
            catch (Exception ex)
            {
                _logger.ErrorException("in OnStart", ex);
            }
        }

        protected override void OnStop()
        {
            try
            {
                _logger.Info("stop requested");
                _stopRequested = true;
                _serviceThread.Join(11100);
                _logger.Info("stopped");
            }
            catch (Exception ex)
            {
                _logger.ErrorException("in OnStop", ex);
            }
        }

        public void ProcessLoop()
        {
            Basf.ServiceStackUtils.Configure();

            string port = ConfigurationManager.AppSettings.Get("port");
            if (String.IsNullOrWhiteSpace(port))
                port = "8080";
            string server = ConfigurationManager.AppSettings.Get("server");
            if (String.IsNullOrWhiteSpace(server))
                server = "*";

            var urlBase = String.Format("http://{0}:{1}/", server, port);
            _logger.Debug("starting at UrlBase: {0}", urlBase);
            var host = new BasfSvrAppHost();
            host.Init();
            host.Start(urlBase);

            if (Foreground)
                System.Diagnostics.Process.Start("http://localhost:" + port + "/");

            if (Environment.UserInteractive)
            {
                System.Console.WriteLine("<press any key to quit>");
                System.Console.Read();
            }
        }
    }
}
