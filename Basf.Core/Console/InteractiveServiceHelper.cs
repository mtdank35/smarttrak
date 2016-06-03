using NLog;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Console.Services
{
    public class InteractiveServiceHelper
    {
        private static Logger _log = LogManager.GetCurrentClassLogger();

        public string ServiceName { get; set; }
        public IWindowsService ServiceImplementation { get; set; }

        public InteractiveServiceHelper(string serviceName, IWindowsService serviceImplementation)
        {
            ServiceName = serviceName;
            ServiceImplementation = serviceImplementation;
        }

        public void ProcessCommandLine<T>(string[] args) where T : ICmdSvcArgs
        {
            var opt = (T)Activator.CreateInstance(typeof(T));
            if (CommandLine.Parser.Default.ParseArguments(args, opt))
            {
                if (opt.Start)
                    StartService();
                else if (opt.Stop)
                    StopService();
                else if (opt.Install)
                    InstallService();
                else if (opt.Uninstall)
                    UninstallService();
                else if (opt.Query)
                    QueryService();
                else if (opt.Run)
                {
                    if (Environment.UserInteractive)
                        _log.Info("starting as foreground process");
                    RunForeground(opt, args);
                }
                else
                    _log.Info(opt.GetUsage(ServiceName));
            }
            else
                _log.Info(opt.GetUsage(ServiceName));
        }

        private void RunForeground<T>(T opt, string[] args) where T : ICmdSvcArgs
        {
            ServiceImplementation.Foreground = true;
            if (opt.RunOnce)
                ServiceImplementation.RunOnce = true;
            ServiceImplementation.Args = args;
            ServiceImplementation.ProcessLoop();
        }

        public void StartService()
        {
            try
            {
                ServiceController sc = new ServiceController(ServiceName);
                if (sc.Status == ServiceControllerStatus.Stopped)
                {
                    string msg = String.Format("Starting service '{0}'", ServiceName);
                    _log.Info(msg);
                    sc.Start();
                }
                sc.Close();
            }
            catch (Exception ex)
            {
                _log.ErrorException("Error starting service", ex);
            }
        }

        public void StopService()
        {
            try
            {
                ServiceController sc = new ServiceController(ServiceName);
                if (sc.Status == ServiceControllerStatus.Running)
                {
                    string msg = String.Format("Stopping service '{0}'", ServiceName);
                    _log.Info(msg);
                    sc.Stop();
                }
                sc.Close();
            }
            catch (Exception ex)
            {
                _log.ErrorException("Error stopping service", ex);
            }
        }

        public void InstallService()
        {
            try
            {
                string msg = String.Format("Installing service '{0}'", ServiceName);
                _log.Info(msg);

                Assembly assembly = Assembly.GetEntryAssembly();
                System.Configuration.Install.AssemblyInstaller installer = new System.Configuration.Install.AssemblyInstaller(assembly, null);
                installer.UseNewContext = true;
                installer.Install(null);
                installer.Commit(null);
                _log.Info("Service installed");
            }
            catch (Exception ex)
            {
                _log.ErrorException("Error installing service", ex);
            }
        }

        public void UninstallService()
        {
            try
            {
                // don't uninstall if service is already running
                try
                {
                    var sc = new ServiceController(ServiceName);
                    if (sc.Status == ServiceControllerStatus.Running)
                    {
                        _log.Error("Stop service before uninstalling");
                        return;
                    }
                }
                catch
                {
                    _log.Info("Service not installed.");
                    return;
                }

                string msg = String.Format("Uninstalling service '{0}'", ServiceName);
                _log.Info(msg);
                Assembly assembly = Assembly.GetEntryAssembly();
                System.Configuration.Install.AssemblyInstaller installer = new System.Configuration.Install.AssemblyInstaller(assembly, null);
                installer.UseNewContext = true;
                installer.Uninstall(null);
                _log.Info("Service uninstalled");
            }
            catch (Exception ex)
            {
                _log.ErrorException("Error uninstalling service", ex);
            }
        }

        public void QueryService()
        {
            ServiceController sc = null;
            try
            {
                sc = new ServiceController(ServiceName);
                _log.Info("Service is {0}", sc.Status);
            }
            catch (Exception ex)
            {
                _log.ErrorException("Error querying service", ex);
                return;
            }
        }
    }
}
