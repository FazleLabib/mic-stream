using NAudio.Wave;
using System;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

namespace MicReceiver.Services
{
    public class AudioStreamServer
    {
        private TcpListener _listener;
        private WaveOut _waveOut;
        private BufferedWaveProvider _bufferedWaveProvider;
        private bool _isRunning = false;

        public event Action<string> StatusUpdated;

        public async Task StartAsync(string ip, int port, int deviceNumber, CancellationToken cancellationToken)
        {
            _listener = new TcpListener(IPAddress.Parse(ip), port);
            _listener.Start();
            _isRunning = true;

            StatusUpdated?.Invoke($"Server listening on {ip}:{port}");
            StatusUpdated?.Invoke($"Using output device: {WaveOut.GetCapabilities(deviceNumber).ProductName}");

            try
            {
                while (!cancellationToken.IsCancellationRequested)
                {
                    var acceptTask = _listener.AcceptTcpClientAsync();

                    var completedTask = await Task.WhenAny(acceptTask, Task.Delay(1000, cancellationToken));

                    if (completedTask == acceptTask && !cancellationToken.IsCancellationRequested)
                    {
                        var client = await acceptTask;
                        _ = HandleClientAsync(client, deviceNumber, cancellationToken);
                    }
                }
            }
            catch (OperationCanceledException)
            {
                // Expected when cancellation is requested
            }
            catch (Exception ex)
            {
                StatusUpdated?.Invoke($"Error in server: {ex.Message}");
            }
            finally
            {
                _listener.Stop();
                _isRunning = false;
            }
        }

        public void Stop()
        {
            if (_isRunning)
            {
                _listener?.Stop();
                _waveOut?.Stop();
                _waveOut?.Dispose();
                _isRunning = false;
            }
        }

        private async Task HandleClientAsync(TcpClient client, int deviceNumber, CancellationToken cancellationToken)
        {
            try
            {
                string clientEndPoint = client.Client.RemoteEndPoint.ToString();
                StatusUpdated?.Invoke($"Client connected from {clientEndPoint}");

                using (var stream = client.GetStream())
                {
                    SetupPlayback(deviceNumber);

                    var buffer = new byte[4096];
                    int bytesRead;

                    while (!cancellationToken.IsCancellationRequested &&
                           (bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length, cancellationToken)) > 0)
                    {
                        _bufferedWaveProvider?.AddSamples(buffer, 0, bytesRead);
                    }
                }

                StatusUpdated?.Invoke($"Client {clientEndPoint} disconnected");
                _waveOut?.Stop();
            }
            catch (OperationCanceledException)
            {
                // Expected when cancellation is requested
            }
            catch (Exception ex)
            {
                StatusUpdated?.Invoke($"Error handling client: {ex.Message}");
            }
            finally
            {
                client.Dispose();
            }
        }

        private void SetupPlayback(int deviceNumber)
        {
            var waveFormat = new WaveFormat(16000, 16, 1);
            _bufferedWaveProvider = new BufferedWaveProvider(waveFormat)
            {
                BufferDuration = TimeSpan.FromSeconds(5)
            };

            _waveOut = new WaveOut { DeviceNumber = deviceNumber };
            _waveOut.Init(_bufferedWaveProvider);
            _waveOut.Play();

            StatusUpdated?.Invoke("Audio playback initialized");
        }
    }
}
