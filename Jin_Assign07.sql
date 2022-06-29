-- Question 1:

USE NYCTaxi_Sample;

EXECUTE sp_execute_external_script 
		@language = N'R'
        , @script = N'data <- InputDataSet;
					  data <- data[1:100000, ];
					  split_dummy <- sample(c(rep(0, 0.75 * nrow(data)),  
											  rep(1, 0.25 * nrow(data))));
					  data_train <- data[split_dummy == 0, ];  
				      data_test <- data[split_dummy == 1, ];
				      library(RevoScaleR);
					  DTree <- rxDTree(tipped ~ trip_distance + passenger_count + trip_time_in_secs 
					  + fare_amount + surcharge + mta_tax, data = data_train);
				      rawPred <- rxPredict(DTree, data = data_test)
				      Pred <- rep(0, nrow(rawPred))
				      Pred[rawPred >= 0.5] = 1
				      OutputDataSet <- data.frame(cbind(data_test[, 1], Pred, rawPred));'
        , @input_data_1 = N'select tipped, trip_distance, passenger_count, trip_time_in_secs, fare_amount, surcharge, mta_tax
                            from dbo.NYCTaxi_Sample TABLESAMPLE(100000 ROWS) REPEATABLE (123);'
WITH RESULT SETS(( Actual INT,
				   Predicted INT,
				   Pred_Raw FLOAT));

-- Question 2:

USE HFRI;

-- stepwise regression

EXECUTE sp_execute_external_script
    @language = N'R'
    , @script = N'library(RevoScaleR);
				  varsel <- rxStepControl(method = "stepwise")
				  results <- rxLinMod(HFRIFOF ~ 
									  HFRIAWJ+HFRIAWC+HFRICRDT+HFRIDVRS+HFRIACT+
									  HFRICRED+HFRIDSI+HFRIMAI+HFRIEDMS+HFRIEDSS+HFRIEMNI+HFRIEHFG+
									  HFRIEHFV+HFRIEHMS+HFRIENHI+HFRISEN+HFRIHLTH+HFRITECH+HFRISTI+
								      HFRIEM+HFRIEMA+HFRICHN+HFRIEMG+HFRIIND+HFRIEMLA+HFRIMENA+HFRICIS+
									  HFRIEHI+HFRIAWEH+HFRIEDI+HFRIAWED+HFRIFOFC+HFRIFOFD+HFRIFOFM+
									  HFRIFWI+HFRIFWIC+HFRIFWIE+HFRIFWIG+HFRIFOFS+HFRIWRLD,
									  data = InputDataSet, variableSelection = varsel);
			      coeffs <- results$coefficients;
				  pvals <- results$coef.p.value;
				  rowlabels <- rownames(coeffs);
				  OutputDataSet <- data.frame(cbind(rowlabels, coeffs, pvals));'
    , @input_data_1 = N'SELECT HFRIFOF,HFRIAWJ,HFRIAWC,HFRICRDT,HFRIDVRS,HFRIACT,
						HFRICRED,HFRIDSI,HFRIMAI,HFRIEDMS,HFRIEDSS,HFRIEMNI,HFRIEHFG,
						HFRIEHFV,HFRIEHMS,HFRIENHI,HFRISEN,HFRIHLTH,HFRITECH,HFRISTI,
						HFRIEM,HFRIEMA,HFRICHN,HFRIEMG,HFRIIND,HFRIEMLA,HFRIMENA,HFRICIS,
						HFRIEHI,HFRIAWEH,HFRIEDI,HFRIAWED,HFRIFOFC,HFRIFOFD,HFRIFOFM,
						HFRIFWI,HFRIFWIC,HFRIFWIE,HFRIFWIG,HFRIFOFS,HFRIWRLD
				        FROM dbo.HFRI_Data;'
WITH RESULT SETS(([Name] nvarchar(100), Estimate float, P_value float));

/*
Name         Estimate   P_value
(Intercept)	-1.08E-05	0.807221476
HFRIAWC	-0.011898371	0.131928389
HFRIAWED	0.00398275	0.16110454
HFRICIS	-0.002484819	0.084338859
HFRICRDT	0.056350315	0.005856791
HFRICRED	-0.012057611	0.043805319
HFRIEDMS	-0.007405362	0.084450955
HFRIEHFG	0.151623418	0.00506787
HFRIEHFV	0.203794535	0.004848565
HFRIEHI	-0.519493798	0.005700305
HFRIEHMS	0.037016509	0.004961345
HFRIEM	0.026789988	0.023620993
HFRIEMA	-0.010598525	0.014377244
HFRIEMLA	-0.004895887	0.007147704
HFRIEMNI	0.056751102	0.00303758
HFRIENHI	0.032605206	0.014193971
HFRIFOFC	0.114814826	1.01E-07
HFRIFOFD	0.47393875	2.22E-16
HFRIFOFM	0.058642061	5.65E-10
HFRIFOFS	0.349667212	2.22E-16
HFRIFWI	-0.09667301	0.007138918
HFRIFWIC	0.040784931	0.082283741
HFRIHLTH	0.022237641	0.004213383
HFRIIND	-0.000996099	0.089919637
HFRIMAI	-0.003645252	0.224659972
HFRISEN	0.018547789	0.006964945
HFRITECH	0.025132262	0.008159691

27
*/

-- forward regression

EXECUTE sp_execute_external_script
    @language = N'R'
    , @script = N'library(RevoScaleR);
				  varsel <- rxStepControl(method = "forward")
				  results <- rxLinMod(HFRIFOF ~ 
									  HFRIAWJ+HFRIAWC+HFRICRDT+HFRIDVRS+HFRIACT+
									  HFRICRED+HFRIDSI+HFRIMAI+HFRIEDMS+HFRIEDSS+HFRIEMNI+HFRIEHFG+
									  HFRIEHFV+HFRIEHMS+HFRIENHI+HFRISEN+HFRIHLTH+HFRITECH+HFRISTI+
								      HFRIEM+HFRIEMA+HFRICHN+HFRIEMG+HFRIIND+HFRIEMLA+HFRIMENA+HFRICIS+
									  HFRIEHI+HFRIAWEH+HFRIEDI+HFRIAWED+HFRIFOFC+HFRIFOFD+HFRIFOFM+
									  HFRIFWI+HFRIFWIC+HFRIFWIE+HFRIFWIG+HFRIFOFS+HFRIWRLD,
									  data = InputDataSet, variableSelection = varsel);
			      coeffs <- results$coefficients;
				  pvals <- results$coef.p.value;
				  rowlabels <- rownames(coeffs);
				  OutputDataSet <- data.frame(cbind(rowlabels, coeffs, pvals));'
    , @input_data_1 = N'SELECT HFRIFOF,HFRIAWJ,HFRIAWC,HFRICRDT,HFRIDVRS,HFRIACT,
						HFRICRED,HFRIDSI,HFRIMAI,HFRIEDMS,HFRIEDSS,HFRIEMNI,HFRIEHFG,
						HFRIEHFV,HFRIEHMS,HFRIENHI,HFRISEN,HFRIHLTH,HFRITECH,HFRISTI,
						HFRIEM,HFRIEMA,HFRICHN,HFRIEMG,HFRIIND,HFRIEMLA,HFRIMENA,HFRICIS,
						HFRIEHI,HFRIAWEH,HFRIEDI,HFRIAWED,HFRIFOFC,HFRIFOFD,HFRIFOFM,
						HFRIFWI,HFRIFWIC,HFRIFWIE,HFRIFWIG,HFRIFOFS,HFRIWRLD
				        FROM dbo.HFRI_Data;'
WITH RESULT SETS(([Name] nvarchar(100), Estimate float, P_value float));

/*
Name         Estimate   P_value
(Intercept)	-1.80E-06	0.992171748
HFRIAWJ	0.004715214	0.694564169
HFRIAWC	-0.012545833	0.657069111
HFRICRDT	0.054460903	0.490056073
HFRIDVRS	0.010292405	0.466428362
HFRIACT	0.001075484	0.930696482
HFRICRED	-0.011999901	0.648804561
HFRIDSI	-0.002110475	0.969839944
HFRIMAI	-0.009003443	0.779464483
HFRIEDMS	-0.011421026	0.726516003
HFRIEDSS	-0.004110951	0.951171036
HFRIEMNI	0.05720154	0.299248206
HFRIEHFG	0.135808891	0.344128885
HFRIEHFV	0.190860053	0.334199831
HFRIEHMS	0.032828638	0.329031013
HFRIENHI	0.026009643	0.508325312
HFRISEN	0.017084984	0.361977537
HFRIHLTH	0.050639075	0.424040049
HFRITECH	0.058672919	0.431469583
HFRISTI	-0.062128584	0.562647822
HFRIEM	0.053257203	0.580675718
HFRIEMA	-0.015248869	0.695241419
HFRICHN	-0.003971333	0.633973168
HFRIEMG	-0.007360723	0.78842438
HFRIIND	-0.001615268	0.513375036
HFRIEMLA	-0.009017113	0.490151002
HFRIMENA	-0.001739091	0.825092913
HFRICIS	-0.004193609	0.575152763
HFRIEHI	-0.483367784	0.343668957
HFRIAWEH	-0.001587854	0.921110827
HFRIEDI	0.013706012	0.9477979
HFRIAWED	0.002942853	0.716583265
HFRIFOFC	0.104719773	0.015902207
HFRIFOFD	0.476745843	3.48E-06
HFRIFOFM	0.060487864	0.00293793
HFRIFWI	-0.114191444	0.475394587
HFRIFWIC	0.050172311	0.771615836
HFRIFWIE	0.000740038	0.996036263
HFRIFWIG	0.004367412	0.980083471
HFRIFOFS	0.351103977	3.78E-06
HFRIWRLD	0.000346623	0.995268959

41
*/

-- backward regression

EXECUTE sp_execute_external_script
    @language = N'R'
    , @script = N'library(RevoScaleR);
				  varsel <- rxStepControl(method = "backward")
				  results <- rxLinMod(HFRIFOF ~ 
									  HFRIAWJ+HFRIAWC+HFRICRDT+HFRIDVRS+HFRIACT+
									  HFRICRED+HFRIDSI+HFRIMAI+HFRIEDMS+HFRIEDSS+HFRIEMNI+HFRIEHFG+
									  HFRIEHFV+HFRIEHMS+HFRIENHI+HFRISEN+HFRIHLTH+HFRITECH+HFRISTI+
								      HFRIEM+HFRIEMA+HFRICHN+HFRIEMG+HFRIIND+HFRIEMLA+HFRIMENA+HFRICIS+
									  HFRIEHI+HFRIAWEH+HFRIEDI+HFRIAWED+HFRIFOFC+HFRIFOFD+HFRIFOFM+
									  HFRIFWI+HFRIFWIC+HFRIFWIE+HFRIFWIG+HFRIFOFS+HFRIWRLD,
									  data = InputDataSet, variableSelection = varsel);
			      coeffs <- results$coefficients;
				  pvals <- results$coef.p.value;
				  rowlabels <- rownames(coeffs);
				  OutputDataSet <- data.frame(cbind(rowlabels, coeffs, pvals));'
    , @input_data_1 = N'SELECT HFRIFOF,HFRIAWJ,HFRIAWC,HFRICRDT,HFRIDVRS,HFRIACT,
						HFRICRED,HFRIDSI,HFRIMAI,HFRIEDMS,HFRIEDSS,HFRIEMNI,HFRIEHFG,
						HFRIEHFV,HFRIEHMS,HFRIENHI,HFRISEN,HFRIHLTH,HFRITECH,HFRISTI,
						HFRIEM,HFRIEMA,HFRICHN,HFRIEMG,HFRIIND,HFRIEMLA,HFRIMENA,HFRICIS,
						HFRIEHI,HFRIAWEH,HFRIEDI,HFRIAWED,HFRIFOFC,HFRIFOFD,HFRIFOFM,
						HFRIFWI,HFRIFWIC,HFRIFWIE,HFRIFWIG,HFRIFOFS,HFRIWRLD
				        FROM dbo.HFRI_Data;'
WITH RESULT SETS(([Name] nvarchar(100), Estimate float, P_value float));

/*
Name         Estimate   P_value
(Intercept)	-1.08E-05	0.807221476
HFRIAWC	-0.011898371	0.131928389
HFRIAWED	0.00398275	0.16110454
HFRICIS	-0.002484819	0.084338859
HFRICRDT	0.056350315	0.005856791
HFRICRED	-0.012057611	0.043805319
HFRIEDMS	-0.007405362	0.084450955
HFRIEHFG	0.151623418	0.00506787
HFRIEHFV	0.203794535	0.004848565
HFRIEHI	-0.519493798	0.005700305
HFRIEHMS	0.037016509	0.004961345
HFRIEM	0.026789988	0.023620993
HFRIEMA	-0.010598525	0.014377244
HFRIEMLA	-0.004895887	0.007147704
HFRIEMNI	0.056751102	0.00303758
HFRIENHI	0.032605206	0.014193971
HFRIFOFC	0.114814826	1.01E-07
HFRIFOFD	0.47393875	2.22E-16
HFRIFOFM	0.058642061	5.65E-10
HFRIFOFS	0.349667212	2.22E-16
HFRIFWI	-0.09667301	0.007138918
HFRIFWIC	0.040784931	0.082283741
HFRIHLTH	0.022237641	0.004213383
HFRIIND	-0.000996099	0.089919637
HFRIMAI	-0.003645252	0.224659972
HFRISEN	0.018547789	0.006964945
HFRITECH	0.025132262	0.008159691

27
*/