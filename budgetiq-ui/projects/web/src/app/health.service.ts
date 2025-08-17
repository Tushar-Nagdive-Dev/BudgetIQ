import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../environments/environment';

@Injectable({ providedIn: 'root' })
export class HealthService {
  #http = inject(HttpClient);
  check() {
    return this.#http.get<{status: string}>(`${environment.apiBase}/actuator/health`);
  }
}
