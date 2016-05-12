using System.IO;
using System.Linq;

namespace BasfCli.Commands.Misc
{
	[CommandHelp("Display system information")]
	public class SysinfoCommand : ApplicationCommand
	{
		private readonly TextWriter _writer;

		public SysinfoCommand(TextWriter writer)
		{
			_writer = writer;
		}

		protected override void InnerExecute(string[] arguments)
		{
			_writer.WriteLine("TODO: show system info...");
		}
	}
}
