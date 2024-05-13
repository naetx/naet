using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.Metrics;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Naet.Hosting;

public class NaetHostBuilder : IHostApplicationBuilder
{
    private IHost? _builtHost;

    private readonly HostApplicationBuilder _hostApplicationBuilder;    

    public IDictionary<object, object> Properties => ((IHostApplicationBuilder)_hostApplicationBuilder).Properties;

    public IConfigurationManager Configuration => _hostApplicationBuilder.Configuration;

    public IHostEnvironment Environment => _hostApplicationBuilder.Environment;

    public ILoggingBuilder Logging => _hostApplicationBuilder.Logging;

    public IMetricsBuilder Metrics => _hostApplicationBuilder.Metrics;

    public IServiceCollection Services => _hostApplicationBuilder.Services;

    public NaetHostBuilder(HostBuilderOptions options)
    {
        var configuration = new ConfigurationManager();

        configuration.AddEnvironmentVariables(prefix: "NAET_");

        _hostApplicationBuilder = new HostApplicationBuilder(new HostApplicationBuilderSettings
        {
            Args = options.Args,
            ApplicationName = options.ApplicationName,
            EnvironmentName = options.EnvironmentName,
            ContentRootPath = options.ContentRootPath,
            Configuration = configuration,
        });
    }

    public void ConfigureContainer<TContainerBuilder>(IServiceProviderFactory<TContainerBuilder> factory, Action<TContainerBuilder>? configure = null) where TContainerBuilder : notnull
    {
        _hostApplicationBuilder.ConfigureContainer(factory, configure);
    }

    public IHost Build()
    {
        _builtHost = _hostApplicationBuilder.Build();
        return _builtHost;
    }

    public static NaetHostBuilder Create(string[]? args)
    {
        return new NaetHostBuilder(new HostBuilderOptions { Args = args });
    }
}
