using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Console.Services
{
    public interface ICmdSvcArgs
    {
        bool Start { get; set; }
        bool Stop { get; set; }
        bool Install { get; set; }
        bool Uninstall { get; set; }
        bool Query { get; set; }
        bool Run { get; set; }
        bool RunOnce { get; set; }
        string GetUsage(string svcName);
    }
}
