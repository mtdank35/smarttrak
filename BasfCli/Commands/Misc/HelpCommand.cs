﻿using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.IO;
using System.Linq;
using System.Text;

namespace BasfCli.Commands.Misc
{
	[CommandHelp("Display help summary")]
	public class HelpCommand : Command
	{
		private readonly IEnumerable<Type> _commandTypes;
		private readonly TextWriter _writer;

		public HelpCommand(IEnumerable<Type> commandTypes, TextWriter writer)
		{
			_commandTypes = commandTypes;
			_writer = writer;
		}

		protected override void InnerExecute(string[] arguments)
		{
			_writer.WriteLine("Usage: basfcli COMMAND [command-options]\n");

			string priorNamespace = null;

			foreach (var commandType in _commandTypes.Where(x => x.IsClass)
				.OrderBy(x => GetNamespace(x))
				.ThenBy(x => GetScope(x))
				.ThenBy(x => x.Name))
			{

				var currNamespace = GetNamespace(commandType);
				if (priorNamespace == null || priorNamespace != currNamespace)
				{
					using (new ForegroundColor(ConsoleColor.Cyan))
					{
						_writer.WriteLine("\n{0} commands:", currNamespace);
					}
					priorNamespace = currNamespace;
				}
		
				var usageStringBuilder = new StringBuilder();

				var splitted = SplitUpperCase(commandType.Name).Where(x => x != "Command");
				usageStringBuilder.Append("  ");
				usageStringBuilder.Append(string.Join(" ", splitted.Reverse()));
				var helpAttribute = commandType.GetCustomAttributes(true).OfType<CommandHelpAttribute>().Single();
					usageStringBuilder.Append(string.Format(" {0}", helpAttribute.Options));

				while (usageStringBuilder.Length < 40)
				{
					usageStringBuilder.Append(" ");
				}

				_writer.Write(usageStringBuilder.ToString().ToLower());
				_writer.Write(string.Concat("#  ", helpAttribute.Description));

				if (!string.IsNullOrEmpty(helpAttribute.Alias))
				{
					_writer.Write(" (\"{0}\")", helpAttribute.Alias);
				}
				_writer.WriteLine();
			}

			_writer.WriteLine();
			_writer.WriteLine("Common options:");
			OptionSet.WriteOptionDescriptions(_writer);
		}

		private static string GetNamespace(Type x)
		{
			var parts = x.Namespace.Split('.');
			return parts.Last();
		}

		private static string GetScope(Type x)
		{
			return SplitUpperCase(x.Name).Where(y => y != "Command").Last();
		}

		private static string Reverse(string sz)
		{
			if (string.IsNullOrEmpty(sz) || sz.Length == 1)
			{
				return sz;
			}

			var chars = sz.ToCharArray();
			Array.Reverse(chars);

			return new string(chars);
		}

		/// <remarks>
		/// Splitting Pascal/Camel Cased Strings
		/// http://haacked.com/archive/2005/09/23/splitting-pascalcamel-cased-strings.aspx/
		/// Licensed under the terms of the Creative Commons Attribution 2.5 Generic License
		/// </remarks>

		private static string[] SplitUpperCase(string source)
		{
			if (source == null)
			{
				return new string[] { };
			}

			if (source.Length == 0)
			{
				return new string[] { "" };
			}

			var words = new StringCollection();
			int wordStartIndex = 0;

			var letters = source.ToCharArray();

			for (int i = 1; i < letters.Length; i++)
			{
				if (char.IsUpper(letters[i]))
				{
					words.Add(new String(letters, wordStartIndex, i - wordStartIndex));
					wordStartIndex = i;
				}
			}

			words.Add(new String(letters, wordStartIndex, letters.Length - wordStartIndex));

			var wordArray = new string[words.Count];
			words.CopyTo(wordArray, 0);

			return wordArray;
		}
	}
}
