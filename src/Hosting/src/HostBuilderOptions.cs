namespace Naet.Hosting;

public class HostBuilderOptions
{
    /// <summary>
    /// The command line arguments.
    /// </summary>
    public string[]? Args { get; init; }

    /// <summary>
    /// The environment name.
    /// </summary>
    public string? EnvironmentName { get; init; }

    /// <summary>
    /// The application name.
    /// </summary>
    public string? ApplicationName { get; init; }

    /// <summary>
    /// The content root path.
    /// </summary>
    public string? ContentRootPath { get; init; }
}
