using System.IO;
using System.Linq;
using NDesk.Options;

namespace BasfCli
{
	public abstract class Command
	{

		private readonly OptionSet _optionSet;
		private bool _helpCommand;

		public Command()
		{
			_optionSet = new OptionSet();
			_optionSet.Add("h|?|help", "Show command help", x => _helpCommand = true);
		}

		public virtual void Execute(string[] arguments)
		{
			var commandArguments = OptionSet.Parse(arguments).ToArray();
			if (_helpCommand)
			{
				throw new HelpException();
			}
			InnerExecute(commandArguments);
		}

		protected abstract void InnerExecute(string[] arguments);

		public OptionSet OptionSet
		{
			get
			{
				return _optionSet;
			}
		}

		public void WriteUsage(string invokedWith, TextWriter writer)
		{
			var commandHelpAttribute = this.GetType().GetCustomAttributes(true).OfType<CommandHelpAttribute>().Single();
			writer.WriteLine("Command description: {0}", commandHelpAttribute.Description);
			writer.WriteLine();

			writer.WriteLine("Usage: basfcli {0} {1} [OPTIONS]",
				invokedWith,
				commandHelpAttribute.Options);

			writer.WriteLine();
			writer.WriteLine("Available options:");
			OptionSet.WriteOptionDescriptions(writer);
		}
	}
}
