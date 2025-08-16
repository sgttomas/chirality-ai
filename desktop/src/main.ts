import { app, BrowserWindow, shell, dialog, Menu } from 'electron';
import { spawn, ChildProcess } from 'child_process';
import { join } from 'path';
import Store from 'electron-store';
import { readFileSync, existsSync } from 'fs';

// Store for user preferences
const store = new Store({
  defaults: {
    windowBounds: { width: 1200, height: 800 },
    lastEnvPath: '',
    autoStartBackend: true,
    openDevTools: false
  }
});

interface ServiceStatus {
  neo4j: boolean;
  graphql: boolean;
  admin: boolean;
  frontend: boolean;
}

class ChiralityDesktopApp {
  private mainWindow: any = null;
  private backendProcess: ChildProcess | null = null;
  private frontendProcess: ChildProcess | null = null;
  private statusCheckInterval: NodeJS.Timeout | null = null;
  
  // Paths - configured for post-consolidation setup (Aug 16, 2025)
  private readonly projectRoot = '/Users/ryan/Desktop/ai-env/chirality-ai';          // Docker orchestration
  private readonly frontendDir = '/Users/ryan/Desktop/ai-env/chirality-ai-app';      // Latest chat interface
  private readonly frontendPort = 3000;
  private readonly adminPort = 3001;
  private readonly graphqlPort = 8080;

  constructor() {
    this.setupApp();
  }

  private setupApp() {
    // App event handlers
    app.whenReady().then(() => this.createWindow());
    
    app.on('window-all-closed', () => {
      if (process.platform !== 'darwin') {
        this.cleanup();
        app.quit();
      }
    });

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        this.createWindow();
      }
    });

    app.on('before-quit', () => {
      this.cleanup();
    });
  }

  private async createWindow() {
    const bounds = store.get('windowBounds') as any;
    
    this.mainWindow = new BrowserWindow({
      width: bounds.width,
      height: bounds.height,
      x: bounds.x,
      y: bounds.y,
      title: 'Chirality AI',
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true
      },
      icon: join(__dirname, '../resources/icon.png'),
      show: false // Don't show until ready
    });

    // Setup menu
    this.setupMenu();

    // Save window bounds when moved/resized
    this.mainWindow.on('close', () => {
      if (this.mainWindow) {
        store.set('windowBounds', this.mainWindow.getBounds());
      }
    });

    // Open external links in browser
    this.mainWindow.webContents.setWindowOpenHandler(({ url }) => {
      shell.openExternal(url);
      return { action: 'deny' };
    });

    // Start backend services if enabled
    if (store.get('autoStartBackend')) {
      await this.startBackendServices();
    }

    // Start frontend
    await this.startFrontend();

    // Wait for frontend to be ready, then show window
    await this.waitForFrontend();
    
    this.mainWindow.loadURL(`http://localhost:${this.frontendPort}/chirality-core`);
    this.mainWindow.show();

    // Open dev tools if enabled
    if (store.get('openDevTools')) {
      this.mainWindow.webContents.openDevTools();
    }

    // Start status monitoring
    this.startStatusMonitoring();
  }

  private setupMenu() {
    const template: any[] = [
      {
        label: 'Chirality AI',
        submenu: [
          {
            label: 'About Chirality AI',
            click: () => this.showAbout()
          },
          { type: 'separator' },
          {
            label: 'Preferences...',
            accelerator: 'Cmd+,',
            click: () => this.showPreferences()
          },
          { type: 'separator' },
          {
            label: 'Quit',
            accelerator: 'Cmd+Q',
            click: () => app.quit()
          }
        ]
      },
      {
        label: 'Services',
        submenu: [
          {
            label: 'Start Backend Services',
            click: () => this.startBackendServices()
          },
          {
            label: 'Stop Backend Services',
            click: () => this.stopBackendServices()
          },
          { type: 'separator' },
          {
            label: 'Restart Frontend',
            click: () => this.restartFrontend()
          },
          { type: 'separator' },
          {
            label: 'Check Service Status',
            click: () => this.checkServiceStatus()
          }
        ]
      },
      {
        label: 'View',
        submenu: [
          {
            label: 'Reload',
            accelerator: 'Cmd+R',
            click: () => this.mainWindow?.reload()
          },
          {
            label: 'Force Reload',
            accelerator: 'Cmd+Shift+R',
            click: () => this.mainWindow?.webContents.reloadIgnoringCache()
          },
          {
            label: 'Developer Tools',
            accelerator: 'F12',
            click: () => this.mainWindow?.webContents.openDevTools()
          },
          { type: 'separator' },
          {
            label: 'Admin Dashboard',
            click: () => shell.openExternal(`http://localhost:${this.adminPort}`)
          },
          {
            label: 'GraphQL Playground',
            click: () => shell.openExternal(`http://localhost:${this.graphqlPort}/graphql`)
          }
        ]
      },
      {
        label: 'Help',
        submenu: [
          {
            label: 'Documentation',
            click: () => shell.openExternal('https://github.com/sgttomas/Chirality-Framework')
          },
          {
            label: 'Report Issue',
            click: () => shell.openExternal('https://github.com/sgttomas/Chirality-Framework/issues')
          }
        ]
      }
    ];

    const menu = Menu.buildFromTemplate(template);
    Menu.setApplicationMenu(menu);
  }

  private async startBackendServices(): Promise<void> {
    console.log('Starting backend services...');
    
    try {
      // Check if .env exists
      const envPath = join(this.projectRoot, '.env');
      if (!existsSync(envPath)) {
        await this.showEnvSetupDialog();
        return;
      }

      // Run docker compose up
      this.backendProcess = spawn('bash', ['-c', `cd "${this.projectRoot}" && ./scripts/chirality up`], {
        stdio: 'pipe',
        env: process.env
      });

      this.backendProcess.stdout?.on('data', (data) => {
        console.log('Backend stdout:', data.toString());
      });

      this.backendProcess.stderr?.on('data', (data) => {
        console.log('Backend stderr:', data.toString());
      });

      this.backendProcess.on('close', (code) => {
        console.log(`Backend process exited with code ${code}`);
        this.backendProcess = null;
      });

      // Give services time to start
      await this.sleep(5000);
      
    } catch (error) {
      console.error('Failed to start backend services:', error);
      dialog.showErrorBox('Backend Error', `Failed to start backend services: ${error}`);
    }
  }

  private async stopBackendServices(): Promise<void> {
    console.log('Stopping backend services...');
    
    try {
      if (this.backendProcess) {
        this.backendProcess.kill();
        this.backendProcess = null;
      }

      // Run docker compose down
      const stopProcess = spawn('bash', ['-c', `cd "${this.projectRoot}" && ./scripts/chirality down`], {
        stdio: 'pipe'
      });

      await new Promise((resolve) => {
        stopProcess.on('close', resolve);
      });

    } catch (error) {
      console.error('Failed to stop backend services:', error);
    }
  }

  private async startFrontend(): Promise<void> {
    console.log('Starting frontend...');
    
    try {
      this.frontendProcess = spawn('npx', ['next', 'dev'], {
        cwd: this.frontendDir,
        stdio: 'pipe',
        env: { ...process.env, PORT: this.frontendPort.toString() }
      });

      this.frontendProcess.stdout?.on('data', (data) => {
        console.log('Frontend stdout:', data.toString());
      });

      this.frontendProcess.stderr?.on('data', (data) => {
        console.log('Frontend stderr:', data.toString());
      });

      this.frontendProcess.on('close', (code) => {
        console.log(`Frontend process exited with code ${code}`);
        this.frontendProcess = null;
      });

    } catch (error) {
      console.error('Failed to start frontend:', error);
      dialog.showErrorBox('Frontend Error', `Failed to start frontend: ${error}`);
    }
  }

  private async restartFrontend(): Promise<void> {
    if (this.frontendProcess) {
      this.frontendProcess.kill();
      this.frontendProcess = null;
      await this.sleep(2000);
    }
    
    await this.startFrontend();
    await this.waitForFrontend();
    
    this.mainWindow?.reload();
  }

  private async waitForFrontend(): Promise<void> {
    console.log('Waiting for frontend to be ready...');
    
    for (let i = 0; i < 30; i++) { // 30 seconds max
      try {
        const response = await fetch(`http://localhost:${this.frontendPort}`);
        if (response.ok) {
          console.log('Frontend is ready!');
          return;
        }
      } catch (error) {
        // Not ready yet
      }
      
      await this.sleep(1000);
    }
    
    throw new Error('Frontend failed to start within 30 seconds');
  }

  private async checkServiceStatus(): Promise<ServiceStatus> {
    const status: ServiceStatus = {
      neo4j: false,
      graphql: false,
      admin: false,
      frontend: false
    };

    try {
      // Check GraphQL
      const graphqlResponse = await fetch(`http://localhost:${this.graphqlPort}/health`);
      status.graphql = graphqlResponse.ok;
    } catch {}

    try {
      // Check Admin
      const adminResponse = await fetch(`http://localhost:${this.adminPort}/api/health`);
      status.admin = adminResponse.ok;
    } catch {}

    try {
      // Check Neo4j (via admin health check)
      const neo4jResponse = await fetch(`http://localhost:7474`);
      status.neo4j = neo4jResponse.ok;
    } catch {}

    try {
      // Check Frontend
      const frontendResponse = await fetch(`http://localhost:${this.frontendPort}`);
      status.frontend = frontendResponse.ok;
    } catch {}

    console.log('Service status:', status);
    return status;
  }

  private startStatusMonitoring(): void {
    this.statusCheckInterval = setInterval(async () => {
      const status = await this.checkServiceStatus();
      
      // Update window title with status
      if (this.mainWindow) {
        const statusIndicator = Object.values(status).every(s => s) ? '✅' : '⚠️';
        this.mainWindow.setTitle(`Chirality AI ${statusIndicator}`);
      }
    }, 10000); // Check every 10 seconds
  }

  private async showAbout(): Promise<void> {
    const version = app.getVersion();
    const message = `Chirality AI Desktop v${version}\n\nA complete semantic framework for knowledge management and reasoning.\n\nBuilt with Electron, Next.js, Neo4j, and the Chirality Framework.`;
    
    dialog.showMessageBox(this.mainWindow!, {
      type: 'info',
      title: 'About Chirality AI',
      message,
      buttons: ['OK']
    });
  }

  private async showPreferences(): Promise<void> {
    // Simple preferences dialog - could be enhanced with a proper settings window
    const result = await dialog.showMessageBox(this.mainWindow!, {
      type: 'question',
      title: 'Preferences',
      message: 'Chirality AI Preferences',
      detail: `Current settings:\n• Auto-start backend: ${store.get('autoStartBackend')}\n• Open dev tools: ${store.get('openDevTools')}`,
      buttons: ['Toggle Auto-start', 'Toggle Dev Tools', 'Cancel']
    });

    switch (result.response) {
      case 0:
        store.set('autoStartBackend', !store.get('autoStartBackend'));
        break;
      case 1:
        store.set('openDevTools', !store.get('openDevTools'));
        break;
    }
  }

  private async showEnvSetupDialog(): Promise<void> {
    const result = await dialog.showMessageBox(this.mainWindow!, {
      type: 'warning',
      title: 'Environment Setup Required',
      message: 'No .env file found',
      detail: `Please create a .env file at:\n${this.projectRoot}/.env\n\nCopy from .env.example and set your API keys.`,
      buttons: ['Open Folder', 'Cancel']
    });

    if (result.response === 0) {
      shell.showItemInFolder(join(this.projectRoot, '.env.example'));
    }
  }

  private cleanup(): void {
    console.log('Cleaning up...');
    
    if (this.statusCheckInterval) {
      clearInterval(this.statusCheckInterval);
    }

    if (this.frontendProcess) {
      this.frontendProcess.kill();
    }

    if (this.backendProcess) {
      this.backendProcess.kill();
    }
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Start the app
new ChiralityDesktopApp();