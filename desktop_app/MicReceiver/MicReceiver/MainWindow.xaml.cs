using MicReceiver.Services;
using NAudio.Wave;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using MicReceiver.Models;

namespace MicReceiver
{
    public partial class MainWindow : Window
    {
        private AudioStreamServer _server;
        private CancellationTokenSource _cancellationTokenSource;
        private bool _isServerRunning = false;

        public MainWindow()
        {
            InitializeComponent();
            LoadOutputDevices();
            UpdateStatus("Server ready. Press 'Start Server' to begin.");
        }

        private void LoadOutputDevices()
        {
            var devices = new List<DeviceInfo>();
            for (int i = 0; i < WaveOut.DeviceCount; i++)
            {
                var capabilities = WaveOut.GetCapabilities(i);
                devices.Add(new DeviceInfo { DeviceNumber = i, ProductName = capabilities.ProductName });
            }
            OutputDeviceComboBox.ItemsSource = devices;

            if (OutputDeviceComboBox.Items.Count > 0)
                OutputDeviceComboBox.SelectedIndex = 0;
        }

        private async void StartStopButton_Click(object sender, RoutedEventArgs e)
        {
            if (_isServerRunning)
            {
                StopServer();
            }
            else
            {
                await StartServer();
            }
        }

        private async Task StartServer()
        {
            try
            {
                string ipAddress = IpAddressTextBox.Text;
                if (!int.TryParse(PortTextBox.Text, out int port))
                {
                    MessageBox.Show("Please enter a valid port number.", "Invalid Port", MessageBoxButton.OK, MessageBoxImage.Error);
                    return;
                }

                if (OutputDeviceComboBox.SelectedItem == null)
                {
                    MessageBox.Show("Please select an output device.", "No Device Selected", MessageBoxButton.OK, MessageBoxImage.Error);
                    return;
                }

                int selectedDeviceNumber = ((DeviceInfo)OutputDeviceComboBox.SelectedItem).DeviceNumber;

                _cancellationTokenSource = new CancellationTokenSource();
                _server = new AudioStreamServer();
                _server.StatusUpdated += UpdateStatus;

                StartStopButton.Content = "Stop Server";
                IpAddressTextBox.IsEnabled = false;
                PortTextBox.IsEnabled = false;
                OutputDeviceComboBox.IsEnabled = false;
                _isServerRunning = true;

                UpdateStatus($"Starting server on {ipAddress}:{port}...");

                await Task.Run(() => _server.StartAsync(ipAddress, port, selectedDeviceNumber, _cancellationTokenSource.Token));
            }
            catch (Exception ex)
            {
                UpdateStatus($"Error: {ex.Message}");
                StopServer();
            }
        }

        private void StopServer()
        {
            _cancellationTokenSource?.Cancel();
            _server?.Stop();
            _server = null;

            StartStopButton.Content = "Start Server";
            IpAddressTextBox.IsEnabled = true;
            PortTextBox.IsEnabled = true;
            OutputDeviceComboBox.IsEnabled = true;
            _isServerRunning = false;

            UpdateStatus("Server stopped.");
        }

        private void UpdateStatus(string message)
        {
            if (!Dispatcher.CheckAccess())
            {
                Dispatcher.Invoke(() => UpdateStatus(message));
                return;
            }

            StatusTextBox.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}");
            StatusTextBox.ScrollToEnd();
        }

        protected override void OnClosed(EventArgs e)
        {
            StopServer();
            base.OnClosed(e);
        }
    }
}
