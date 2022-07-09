function [opt_val, rho_c, rho_p, zeta_c, zeta_p, alpha_c, alpha_p, ...
        precoder_matrix_k, precoder_c, common_rates] = ...
        CVX_opt_rsma_parameters(rho_c_IC, rho_p_IC, zeta_c_IC, zeta_p_IC, ...
        precoder_matrix_k_IC, precoder_c_IC, K, N_T, u_k, Rth, Pt, h_ov_k, varianceNoise)

% initial conditions
rho_c_old   = rho_c_IC;
rho_p_old   = rho_p_IC;
zeta_c_old  = zeta_c_IC;
zeta_p_old  = zeta_p_IC;
precoder_matrix_k_old = precoder_matrix_k_IC;
precoder_c_old = precoder_c_IC;

% CVX problem
cvx_begin quiet
%     cvx_precision best

    % variables
    variable rho_c(K) nonnegative
    variable rho_p(K) nonnegative
    variable alpha_c(K) nonnegative
    variable alpha_p(K) nonnegative
    variable zeta_c(K) nonnegative
    variable zeta_p(K) nonnegative
    variable common_rates(K) nonnegative
    variable precoder_matrix_k(N_T, K) complex
    variable precoder_c(N_T, 1) complex

    w_obj_value = u_k' * (common_rates + alpha_p);
    maximize( w_obj_value )

    subject to
        
        % constaints (29) and (30)
        1 + rho_c >= power(2, alpha_c);
        1 + rho_p >= power(2, alpha_p);

        % constaints (31) and (32)
        sum(common_rates) <= alpha_c;
        common_rates + alpha_p >= Rth;
        
        for k = 1:K

            interference_term = 0;
            for jj = 1:K
                if k ~= jj
                    interference_term = interference_term + ...
                        square_abs(h_ov_k(:, k)'*precoder_matrix_k(:, jj));
                end
            end
    
            % constraints (36) and (34)
            zeta_p(k) >= interference_term + varianceNoise;
            zeta_c(k) >= interference_term + varianceNoise + square_abs(h_ov_k(:, k)'*precoder_matrix_k(:, k));
        
            % constaint (37)
            square_abs( h_ov_k(:, k)'*precoder_c_old) + ...
                2*real( (h_ov_k(:, k)'*precoder_c_old)' * h_ov_k(:, k)' * (precoder_c - precoder_c_old)) >= ...
                1/4 * ( power( rho_c(k) + zeta_c(k), 2 ) - ...
                2*(rho_c_old(k) - zeta_c_old(k))*(rho_c(k) - zeta_c(k)) + ...
                 power( rho_c_old(k) - zeta_c_old(k), 2 ) );
    
            % constaint (38)
            square_abs( h_ov_k(:, k)'*precoder_matrix_k_old(:, k)) + ...
                2*real( (h_ov_k(:, k)'*precoder_matrix_k_old(:, k))' * h_ov_k(:, k)' * ...
                (precoder_matrix_k(:, k) - precoder_matrix_k_old(:, k))) >= ...
                1/4 * ( power( rho_p(k) + zeta_p(k), 2 ) - ...
                2*(rho_p_old(k) - zeta_p_old(k))*(rho_p(k) - zeta_p(k)) + ...
                 power( rho_p_old(k) - zeta_p_old(k), 2 ) );        

        end

        P = [precoder_c, precoder_matrix_k]; 
        % trace(p * p') <= Pt;
%         sum(sum(pow_abs(P, 2))) <= Pt;
        sum(sum_square_abs(P)) <= Pt;

cvx_end

opt_val = cvx_optval;

end