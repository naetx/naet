using Naet.Features;

namespace Naet.Server.Abstractions;

public interface IServer<T> : IDisposable  where T : notnull
{
    IFeatureCollection Features { get; }

    Task StartAsync(T application, CancellationToken cancellationToken);

    Task StopAsync(CancellationToken cancellationToken);
}
