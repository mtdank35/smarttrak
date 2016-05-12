using System;

namespace BasfCli
{
	public interface ICommandMatcher
	{
		Type GetMatchedType(string commandArgument);
		bool IsSatisfiedBy(string commandArgument);
	}
}
