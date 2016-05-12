using Castle.Windsor;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BasfCli
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.ResetColor();

            JsonConvert.DefaultSettings = (() =>
            {
                var settings = new JsonSerializerSettings();
                settings.Formatting = Formatting.Indented;                      // pretty json
                settings.Converters.Add(new Newtonsoft.Json.Converters.StringEnumConverter());             // save enums as strings, not ints
                settings.DateFormatHandling = DateFormatHandling.IsoDateFormat; // 2012-03-21T05:40Z
                return settings;
            });

            var container = new WindsorContainer()
                .Install(new BasfCliInstaller());

            var commandDispatcher = container.Resolve<CommandDispatcher>();

            try
            {
                commandDispatcher.Dispatch(args);
            }
            catch (DispatchException exception)
            {
                Console.WriteLine();
                using (new ForegroundColor(ConsoleColor.Red))
                    Console.WriteLine("ERROR: {0}", exception.Message);
            }
        }
    }
}
