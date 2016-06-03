using CommandLine;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Console.Services.Args
{
    public class CmdSvcArgs : ICmdSvcArgs
    {
        [VerbOption("start", HelpText = "start the service")]
        public bool Start { get; set; }

        [VerbOption("stop", HelpText = "stop the service")]
        public bool Stop { get; set; }

        [Option('i', "install", HelpText = "install the service")]
        public bool Install { get; set; }

        [Option('u', "uninstall", HelpText = "uninstall the service")]
        public bool Uninstall { get; set; }

        [Option('q', "query", HelpText = "query the service control manager for status")]
        public bool Query { get; set; }

        [Option('r', "run", HelpText = "query the service control manager for status")]
        public bool Run { get; set; }

        [VerbOption("once", HelpText = "execute one time and quit when 'run' command used")]
        public bool RunOnce { get; set; }

        [HelpOption]
        public string GetUsage(string svcName)
        {
            string usage = String.Format(
@"
				
  {0} Service
				
  Commands:
    --start             start the '{0}' service
    --stop              stop the '{0}' service
    --install, -i       install the '{0}' service 
    --uninstall, -u     uninstall the '{0}' service,
    --query, -q         query the service controll manager for '{0}' status
    --run, -r           run the '{0}' service foreground
				
  Options:
    --once, -1      execute one time and quit when 'run' command used
", svcName);
            return usage;
        }
    }
}
