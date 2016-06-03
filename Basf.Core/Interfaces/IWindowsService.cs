using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Console.Services
{
    public interface IWindowsService
    {
        void ProcessLoop();
        bool RunOnce { get; set; }
        bool Foreground { get; set; }
        string[] Args { get; set; }
    }
}
