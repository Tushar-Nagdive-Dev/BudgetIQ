import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { MatChipsModule, MatChipOption } from '@angular/material/chips';
import { CommonModule } from '@angular/common';
import { HealthService } from './health.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    RouterOutlet,
    MatChipsModule,
    CommonModule,
  ],
  // templateUrl: './app.html',
  template: `
    <div style="padding:16px">
      <h2>BudgetIQ</h2>
      <mat-chip-option [color]="online() ? 'primary' : 'warn'" [selected]="true">
        {{ online() ? 'System Online' : 'System Offline' }}
      </mat-chip-option>
    </div>
  `,
  styleUrl: './app.scss'
})
export class App {
  protected readonly title = signal('web');
  online = signal(false);
  constructor(private health: HealthService) {
    this.health.check().subscribe({
      next: res => this.online.set(res?.status === 'UP'),
      error: () => this.online.set(false)
    });
  }
}
