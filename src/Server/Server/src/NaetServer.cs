using Naet.Features;
using Naet.Server.Abstractions;

namespace Naet.Server;

public class NaetServer<T> : IServer<T> where T : notnull
{
    public IFeatureCollection Features => throw new NotImplementedException();

    public Task StartAsync(T application, CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }

    public void Dispose()
    {

    }
}
