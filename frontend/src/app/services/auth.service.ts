import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, BehaviorSubject, throwError } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';

export interface User {
  id: string;
  username: string;
  email: string;
  fullName: string;
  role: string;
  walletId?: string;      // thêm dòng này
  walletStatus?: string;  // thêm dòng này
}

export interface AuthResponse {
  token: string;
  userId: string;
  username: string;
  email: string;
  fullName: string;
  role: string;
  walletId?: string;
  walletStatus?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = '/api/auth';
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    // Load user from localStorage on init
    const userStr = localStorage.getItem('user');
    const token = localStorage.getItem('token');
    if (userStr && token) {
      this.currentUserSubject.next(JSON.parse(userStr));
    }
  }

  login(username: string, password: string): Observable<ApiResponse<AuthResponse>> {
    return this.http.post<ApiResponse<AuthResponse>>(`${this.apiUrl}/login`, {
      username,
      password
    }).pipe(
      tap(response => {
        if (response.success && response.data) {
          // Store token and user info (bổ sung walletId, walletStatus)
          localStorage.setItem('token', response.data.token);
          localStorage.setItem('user', JSON.stringify({
            id: response.data.userId,
            username: response.data.username,
            email: response.data.email,
            fullName: response.data.fullName,
            role: response.data.role,
            walletId: response.data.walletId,
            walletStatus: response.data.walletStatus
          }));
          this.currentUserSubject.next({
            id: response.data.userId,
            username: response.data.username,
            email: response.data.email,
            fullName: response.data.fullName,
            role: response.data.role,
            walletId: response.data.walletId,
            walletStatus: response.data.walletStatus
          });
          
          // Check for redirect URL
          const redirectUrl = localStorage.getItem('redirectUrl');
          if (redirectUrl) {
            localStorage.removeItem('redirectUrl');
          }
        }
      }),
      catchError(this.handleError)
    );
  }

  register(username: string, email: string, password: string, fullName: string): Observable<ApiResponse<AuthResponse>> {
    return this.http.post<ApiResponse<AuthResponse>>(`${this.apiUrl}/register`, {
      username,
      email,
      password,
      fullName
    }).pipe(
      tap(response => {
        if (response.success && response.data) {
          // Store token and user info (bổ sung walletId, walletStatus)
          localStorage.setItem('token', response.data.token);
          localStorage.setItem('user', JSON.stringify({
            id: response.data.userId,
            username: response.data.username,
            email: response.data.email,
            fullName: response.data.fullName,
            role: response.data.role,
            walletId: response.data.walletId,
            walletStatus: response.data.walletStatus
          }));
          this.currentUserSubject.next({
            id: response.data.userId,
            username: response.data.username,
            email: response.data.email,
            fullName: response.data.fullName,
            role: response.data.role,
            walletId: response.data.walletId,
            walletStatus: response.data.walletStatus
          });
          
          // Check for redirect URL
          const redirectUrl = localStorage.getItem('redirectUrl');
          if (redirectUrl) {
            localStorage.removeItem('redirectUrl');
          }
        }
      }),
      catchError(this.handleError)
    );
  }

  logout(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    this.currentUserSubject.next(null);
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  isAuthenticated(): boolean {
    return !!this.getCurrentUser();
  }

  getToken(): string | null {
    return localStorage.getItem('token');
  }

  private handleError(error: HttpErrorResponse) {
    let errorMessage = 'Có lỗi xảy ra';
    
    if (error.error instanceof ErrorEvent) {
      // Client-side error
      errorMessage = `Lỗi: ${error.error.message}`;
    } else {
      // Server-side error
      if (error.status === 403 || error.status === 401) {
        errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      } else if (error.status === 404) {
        errorMessage = 'Không tìm thấy tài nguyên';
      } else if (error.error && error.error.message) {
        errorMessage = error.error.message;
      } else {
        errorMessage = `Lỗi server: ${error.status}`;
      }
    }
    
    return throwError(() => errorMessage);
  }
}
