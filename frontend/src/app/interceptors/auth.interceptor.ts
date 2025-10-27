import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpErrorResponse } from '@angular/common/http';
import { AuthService } from '../services/auth.service';
import { Router } from '@angular/router';
import { catchError, switchMap, throwError } from 'rxjs';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  intercept(req: HttpRequest<any>, next: HttpHandler) {
    const token = this.authService.getToken();
    
    if (token) {
      const cloned = req.clone({
        headers: req.headers.set('Authorization', token)
      });
      
      return next.handle(cloned).pipe(
        catchError((error: HttpErrorResponse) => {
          // Handle 403 Forbidden or 401 Unauthorized
          if (error.status === 403 || error.status === 401) {
            // Clear auth data
            this.authService.logout();
            
            // Show error message to user (you can improve this with a toast/alert service)
            alert('Phiên đăng nhập đã hết hạn hoặc bạn không có quyền truy cập. Vui lòng đăng nhập lại.');
            
            // Redirect to login
            this.router.navigate(['/login']);
          }
          
          return throwError(() => error);
        })
      );
    }
    
    return next.handle(req).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 403 || error.status === 401) {
          alert('Bạn cần đăng nhập để tiếp tục');
          this.router.navigate(['/login']);
        }
        return throwError(() => error);
      })
    );
  }
}

