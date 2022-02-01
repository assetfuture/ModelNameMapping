/* Update sel.users
set currentproject = '200'
where ID  = '959' */

--Aug 30, 2021
--The final result shows only the Matching model names, not Model Ids
--Has added a final sql statement to display the matching model names with Model Id or NULL
--will remove it later once incorporated in the previous result

--march 31c -added the defalut  models and the query- getting 50% or more result
--to get valid model names for the client dirty data set.
--first step is to get the model name provided in the list and separate them into words for word matching
--second step is to find  most matching name in the system
--first task is to look for a perfect match, else look for the word by word match
--first give preference to the names starting with the same like the names in the list eg; Control panel  in Control Panel; Camera
--also like Control panel in Fire Alarm Control Panel; Medium (names containing the name)
--if found, the script will check with any existing similar models by searching similar model names and give matching names
--if the script cannot find any similar models, it will show a 'NULL' value in the matching model name field
--the script will again go through the list of models which has no matching model, then for names with two words, it will try to get a matching name from the Default model names by matching the first word
--the script is tested on the data in the snapshot table SnapShotData..Nuovo_ModelTest_200327/SnapShotData..Nuovo_ModelTest1_200327/SnapShotData..Nuovo_ModelTest2_200327/SnapShotData..Nuovo_ModelTest_200406/
--SnapShotData..Nuovo_ModelTest_200409/SnapShotData..Nuovo_ModelTest_200228/SnapShotData..Nuovo_ModelTest_200213
--The script will connect the current user to Project 200 (Models).
--if the data set contains more than 500 rows, filter the script and run separately for 1 word, 2 words etc.(to reduce the query time) or restrict the number of rows to pass each time

begin --main
   declare @DbUser varchar(50)
   declare @UserID int
   declare @ProfId Varchar(50)
   declare @MaxPost varchar(50)
   declare @PostId Varchar(50)
   declare @MatchId Varchar(50)
   declare @MatchId2 Varchar(50)
   declare @Lastrec Varchar(50)
   declare @MatchName_Cnt int 
   declare @MatchName Varchar(250)
   declare @MatchTaken Varchar(10)
   
   set @MatchTaken = 'N';

   --create temporary tables to store and manipulate data
   drop table if exists #toGetNames
   drop table if exists #toGetNomatch 
   drop table if exists #ToGetDefaultModels
   drop table if exists #ToGetModels
   drop table if exists #ToGetNoName_1
   drop table if exists #ToGetNoName_2
   drop table if exists #TheNameList
   drop table if exists #TheNameList2
   drop table if exists #TheTypeList
   drop table if exists #TheFinal
   drop table if exists #TheFinal2
   drop table if exists #TheFinalList

   --first step is to connect the current user to the project 200 (Models)
   -- get the current user name
   select @DbUser = current_user
   --then get the id of the current user
   select @UserID = id
	 from sel.users
	where DbUser = @DbUser
   --then change the project of the current user to Project 200
   Update sel.users
      set currentproject = '200'
     where ID  =  @UserID 

     --to store all the models with status  = 'A' (active) into the temporary table #ToGetModels, so that the script will access the database only once.
     --remove all the extra characters in the name if any like '-','/','(',')',' ','&' ,';',':'
     select m.id, m.name, 
	        trim(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(m.name,'-',' '),'"',' '),',',' '),'_',' '),'.',' '),'?',' '),'/',' '),'[',' '),']',' '),'{',' '),'}',' ' ),'&',' '),'(',' '),')',' '),';',' '),':',' '),'   ',' '),'  ',' '),'  ',' '))[m_model],
	        m.shortname, m.type,m.ReplacementCost,m.profile, m.ConditionDescriptor 
	   into #ToGetModels
       from sel.models m
      where m.status = 'A'

     --  select * from #ToGetModels
	 --if the script cannnot find a match with the main search pattern, it will take the models from the client set and try to get a match from the default models.
	 --like if the client model is Door;smoke and there is no matching model, so it wll take Door; Solid Timber from the default model set and assign as the matching model
	 --all the default models are stored in the snapshot table Nuovo_DeafultModels
	 --to store all the default models with status  = 'A' (active) into the temporary table #ToGetDefaultModels
     --all the extra characters in the name if any like '-','/','(',')',' ','&' ,';',':' area already removed
     select m.id, m.name, m.[m_model],m.shortname, m.type,m.ReplacementCost,m.profile, m.ConditionDescriptor         
	   into #ToGetDefaultModels
       from SnapShotData..Nuovo_DefaultModels m

      --to store the data to be used in a temporary table #ToGetNoName_1 
      --the charcaters like '-','/','(',')',' ','&',';',':' in the model names are elliminated and stored
	  --can add the values in where condition to filter and see results separately for 1 word, 2 words, 3 words etc - for 1 word give 0, 2 words =1, 3 words  =2, 4words =3, 5 words  = 4, 6words  = 5, for others give >5 
	
      select m.id[m_forId], 
             trim(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(m.name,'-',' '),'"',' '),',',' '),'_',' '),'.',' '),'?',' '),'/',' '),'[',' '),']',' '),'{',' '),'}',' ' ),'&',' '),'(',' '),')',' '),';',' '),':',' '),'   ',' '),'  ',' '),'  ',' '))[m_for],
             m.id[m_fromId],m.name[m_from],m.shortname[m_short], m.name[m_name], @MatchName[Match_Name], m.name[m_modelname],
	         m.name m_word1, m.name m_word2, m.name m_word3, m.name m_word4, m.name m_word5, m.name m_word6,NULL [m_type],NULL[m_cost] ,
	         null m_pos1, null m_pos2, null m_pos3, null m_pos4, null m_pos5, null m_pos6,null m_lastrec,@MatchTaken [m_matchtaken]
        into #ToGetNoName_1
        from SnapShotData..Nuovo_Model_Name_Mapping m
  --   where len(trim(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(m.name,'-',' '),'"',' '),',',' '),'_',' '),'.',' '),'?',' '),'/',' '),'[',' '),']',' '),'{',' '),'}',' ' ),'&',' '),'(',' '),')',' '),';',' '),':',' '),'   ',' '),'  ',' '),'  ',' '))) -
     --      len(replace(trim(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(m.name,'-',' '),'"',' '),',',' '),'_',' '),'.',' '),'?',' '),'/',' '),'[',' '),']',' '),'{',' '),'}',' ' ),'&',' '),'(',' '),')',' '),';',' '),':',' '),'   ',' '),'  ',' '),'  ',' ')),' ','')) = 1
	  --where m.id between 0 and 100
	   order by m_forId 

        select * from #ToGetNoName_1
  
       -- to create temporary tables #ToGetNoName_2, #TheNameList in the same structure as #ToGetNoName_1 and delete the data in them.

       --table #ToGetNoName_2
       select * into #ToGetNoName_2
         from #ToGetNoName_1

       --table #TheProfileList
       select * into #TheNameList
         from #ToGetNoName_2
       select * into #TheNameList2
         from #ToGetNoName_2
       
       --delete the data in the new tables
       delete from #ToGetNoName_2
       delete from #TheNameList
	   delete from #TheNameList2


       --To display the model name and details from the first table
       --the script will work on this table and display the results in the same table
       select nn.m_forId, nn.m_for,nn.m_name,nn.m_modelname, nn.Match_Name
         from #ToGetNoName_1 nn
        order by nn.m_forId

       --the script will fetch each record from the table #ToGetNoNamee_1 and split the model names into separate words and store
       --to fetch each record, each the m_forId in the variable @ProfId
       Select @ProfId = Min(m_forId) 
         From #ToGetNoName_1

       --Loop1 #ToGetNoName
       While @ProfId is not null begin

           -- create a temporary table #ToGetWords to split and store the model names as separate words  
           --declaring the variables required for storing the separated words
	       drop table if exists #ToGetWords
           DECLARE @StringValue VARCHAR(250) 
	       DECLARE @Word1 VARCHAR(250) 
	       DECLARE @Word2 VARCHAR(250) 
	       DECLARE @Word3 VARCHAR(250) 
	       DECLARE @Word4 VARCHAR(250) 
	       DECLARE @Word5 VARCHAR(250) 
	       DECLARE @Word6 VARCHAR(250) 

           -- fro each row of data, get the model name from the list for which the the real model name has to be found(m_forId)
	       select @StringValue = m_for
	         from #ToGetNoName_1
	        where m_forId  = @ProfId;

           --to split and store into words, position of the word in the model name and the rest of the word
              WITH SeparateWords ( StringValue, Word, Position, RestOfLine)
                AS
              (
	           SELECT  @StringValue
                           , CASE CHARINDEX(' ',@StringValue)
                                  WHEN 0 THEN @StringValue
                                       ELSE LEFT(@StringValue,  CHARINDEX(' ',@StringValue) -1)
                             END
                           , 1
                           , CASE CHARINDEX(' ',@StringValue)
                                  WHEN 0 THEN ''
                                       ELSE RIGHT(@StringValue, LEN(@StringValue) - CHARINDEX(' ',@StringValue))
                             END
      	          UNION ALL
                            SELECT  sw.StringValue
                                    , CASE CHARINDEX(' ',RestOfLine)
                                           WHEN 0 THEN RestOfLine
                                                ELSE LEFT(RestOfLine, CHARINDEX(' ',RestOfLine) -1)
                                      END
                                   , Position + 1
                                   , CASE CHARINDEX(' ',RestOfLine)
                                          WHEN 0 THEN ''
                                               ELSE RIGHT(RestOfLine, LEN(RestOfLine) - CHARINDEX(' ',RestOfLine))
                                          END
                  FROM SeparateWords AS sw
                 WHERE sw.RestOfLine != ''
             )

             --to store the Id, modelname, the name split into words, postion of the word in the name and the total number of words in the name
             -- the script only checks upto 6 words in the name, rest is elliminated
             select @ProfId g_ForId,StringValue g_StringValue, Word g_Word, Position g_Position, RestOfLine g_RestOfLine, 
                    null g_word1, null g_word2,null g_word3,null g_word4,null g_word5, null g_word6, null g_lastrec
	           into #ToGetWords
	           from SeparateWords
	          where Position < = 6
              order by g_ForId 
	    --   select * from #ToGetWords
	       
	    --loop 2
            -- the script will fetch each record from the table #ToGetWords 
            -- and insert the model details with the separated words to the table #ToGetNoName_2 from the table #ToGetWords
	        --first get the minumim and maximum number of words in tha particula string
            Select @PostId  = Min(g_Position),
		           @MaxPost = Max(g_Position) 
              From #ToGetWords
        
	    -- the next step is to store the model name annd the name in separated words in one row
	    While @PostId is not null begin
                  -- to extract and store the separated words, position of the word and the total number of the words in each name
		      begin --loop 3
			    if @postId =1 
			       begin --if1
				     select @Word1  = coalesce(gw.g_word,null)					       
				       from #ToGetWords gw
 				      where gw.g_position  = @PostId
				         if @postID  = @MaxPost 
					    begin
					        set @Lastrec  = @MaxPost
  					    end
			       end --if1
					 
			    if @postId =2
			       begin --if2
				     select @Word2  = coalesce(gw.g_word,null) 
				       from #ToGetWords gw
				      where g_position  = @PostId
					 if @postID  = @MaxPost 
					    begin
					         set @Lastrec  = @MaxPost
					    end
			       end --if2

			   if @postId =3 
			      begin --if3
				    select @Word3  = coalesce(gw.g_word ,null)
				      from #ToGetWords gw
				     where g_position  = @PostId
					if @postID  = @MaxPost 
					   begin
					        set @Lastrec  = @MaxPost
					   end
			      end --if3
				  
                          if @postId =4
			     begin --if4
				   select @Word4  = coalesce(gw.g_word ,null) 
				     from #ToGetWords gw
			            where g_position  = @PostId
				       if @postID  = @MaxPost 
					  begin
					       set @Lastrec  = @MaxPost
					  end
		             end --if4
				
                         if @postId =5
			    begin --if5
				  select @Word5  = coalesce(gw.g_word,null) 
				    from #ToGetWords gw
				   where g_position  = @PostId
				      if @postID  = @MaxPost 
					 begin
					      set @Lastrec  = @MaxPost
					  end
		            end --if5
				  
                         if @postId =6
		            begin --if6
				  select @Word6  = coalesce(gw.g_word ,null)
				    from #ToGetWords gw
				   where gw.g_position  = @PostId
				      if @postID  = @MaxPost 
					 begin
					      set @Lastrec  = @MaxPost
					  end
			    end --if6
	         	
		   end --loop3

		   Select @PostId = Min(g_Position) 
                     From #ToGetWords 
                    Where (g_Position > @PostId or g_Position > 6)

	    end --loop2

	    Select @ProfId = Min(m_forId) 
          From #ToGetNoName_1
         Where m_forId > @ProfId
            
	    --insert the model names and the separated words of each model name into the table #ToGetNoName_2
   	    insert into #ToGetNoName_2(m_forId, m_for,m_from,m_name,m_type,m_cost,m_modelname,m_matchtaken, m_word1,m_word2, m_word3,m_word4,m_word5,m_word6,m_lastrec)
        select distinct np.m_forid, np.m_for,np.m_from,NULL,NULL,NULL,NULL,@MatchTaken,@Word1,@Word2,@Word3,@Word4,@Word5,@Word6,@Lastrec	    
	      from #ToGetNoName_1 np, #ToGetWords gw
	     where np.m_For  = gw.g_StringValue
        -- and np.m_forid  = @ProfId 
 	       and gw.g_Position  = @Lastrec
             
        --reinitialize the variables used in the above part of the query         
         set @Word1 = null;
	     set @Word2  = null;
	     set @Word3 = null;
         set @Word4 = null;
	     set @Word5 = null;
	     set @Word6 = null;
					 
	 end--loop1
	 
        --to display the model names and the names  with separated words	 
        select distinct nn.m_forId, nn.m_for,nn.m_from,nn.m_name,nn.m_modelname,nn.m_matchtaken,nn.m_type,nn.m_cost,nn.m_word1,nn.m_word2, nn.m_word3,nn.m_word4,nn.m_word5,nn.m_word6,nn.m_lastrec, nn.m_from
          from #ToGetNoName_2 nn
         order by nn.m_forId
		 
       --After getting all the model names and the names as separated words, the script will search for similar model names and find a matching model names
       --to find the matching model names

       --to fetch each record and find the matching model from the table #ToGetNoName_2
      Select @MatchId = Min(m_forId) 
         From #ToGetNoName_2
		
       --Loop Final
      While @MatchId is not null begin
   	        --For the list of Model Names provided, the script will search for the  Model names in the list 
   	        --It takes the Model Names fields in the #ToGetNoName table 
            --first task is to find a perfect match or a name with that syring in it ex: Access Control Field Devices as it is or inside a string as Access Control Field Devices% 
            --if the the script finds a match it will do the search with the exact same name given in the list and insert into the table
            --if the script cannot find a match it will do the word by word matching search and insert into the table
	         select @MatchName_Cnt =  count(distinct (m.id))
			        -- distinct nn.m_forId,nn.m_for,nn.m_from,nn.m_from,m.id ,m.name,m.shortname, coalesce(m.name,null)
		       from #ToGetModels m, #ToGetNoName_2 nn
	          where nn.m_forId  = @MatchId
              --and m.name    = nn.m_from		   
   	            and m.m_model = nn.m_for
		 
		  
		  --if a perfect match is found
		  --insert that model name into the table #TheNameList
		  if @MatchName_Cnt  >= 1
		      begin
			   insert into #TheNameList(m_forId, m_for,m_fromId, m_from,m_short,m_type,m_modelname,m_matchtaken,m_cost,m_name)
	           select nn.m_forId,nn.m_for,m.id ,m.name,m.shortname,m.Type,m.m_model,@MatchTaken,m.ReplacementCost,coalesce(m.name,null)
                 from #ToGetModels m, #ToGetNoName_2 nn
                where nn.m_forId = @MatchId
		       -- and m.name  = nn.m_from				 
		          and m.m_model = nn.m_for
		      end
		  else
		     --if no perfect macth is found, then do the wild card search with different combinations using the separated words in the name
			 --('%',' ','%' has been added with space inorder to avoid getting meaningless names like when searching a name starting with the word Air,
			 --it should retrieve names which has the word Air in it  and not Chair or Hair
			
             insert into #TheNameList(m_forId, m_for,m_fromId, m_from,m_short,m_type,m_modelname,m_matchtaken,m_cost,m_name)
	         select nn.m_forId,nn.m_for,m.id ,m.name,m.shortname,m.Type,m.m_model,@MatchTaken,m.ReplacementCost,coalesce(m.name,null)
               from #ToGetModels m, #ToGetNoName_2 nn
              where nn.m_forId = @MatchId    
               and ((m.m_model like nn.m_for or m.m_model like trim(concat('%',' ',nn.m_for,' ','%')) or m.m_model like concat(nn.m_for,' ','%') or m.m_model like trim(concat(' ','%',nn.m_for))) or
			        -- for model names with one word
			       ((nn.m_lastrec = 1 and (((m.m_model like m_word1) or (m.m_model like concat(m_word1,' ','%')) or (m.m_model like concat('%',' ',m_word1,' ','%')) or (m.m_model like concat('%',' ',m_word1))) or
			                               --for names which has 's' at the end -- tohandle the mismatch in names like Drain and Drains , seat and seats
			                               ((m.m_model like substring(m_word1,1,len(m_word1)-1)) or (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))  or
							   		        (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')) or  (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))) ))) or 
			                                                    
			       --for names with 2 words  ltrim((concat('%',' ','Air','%','Dryer'))) or name like (concat('Air','%','Dryer','%')))
				   (nn.m_lastrec = 2 and ((m.m_model like concat(m_word1,' ',m_word2) or
				                           m.m_model like concat(m_word1,' ',m_word2,' ','%') or
				  						   m.m_model like concat('%',' ',m_word1,' ',m_word2) or
										   m.m_model like concat('%',' ',m_word1,' ',m_word2,' ','%') or
									      (m.m_model like concat(m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2)) or m.m_model like m_word1 ) or 
									   -- (m.m_model like concat(m_word1,' ','%') and ((m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2)) or (m.m_model like m_word1 or m.m_model like concat(m_word1,' ','%') )) or 
									      (m.m_model like concat('%',' ',m_word1) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%')) or m.m_model like m_word1 ) or  
									  --  (m.m_model like concat('%',' ',m_word1) and ((m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%')) or (m.m_model like m_word1 or m.m_model like concat('%',' ',m_word1) ) ) or  
								          (m.m_model like concat('%',' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') 
										                                                   or  m.m_model like concat('%',' ',m_word2)) or m.m_model like m_word1 ) or
									  --  (m.m_model like concat('%',' ',m_word1,' ','%') and ((m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') 
										                                            --     or m.m_model like concat('%',' ',m_word2)) or (m.m_model like m_word1 or m.m_model like concat('%',' ',m_word1,' ','%'))) or
										   m.m_model like concat(m_word2,' ',m_word1) or
										   m.m_model like concat(m_word2,' ',m_word1,' ','%')or
										   m.m_model like concat('%',' ',m_word2,' ',m_word1) or
										   m.m_model like concat('%',' ',m_word2,' ',m_word1,' ','%') or
									      (m.m_model like concat(m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)) or m.m_model like m_word2 )  or
									      (m.m_model like concat('%',' ',m_word2) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%')) or m.m_model like m_word2 ) or  
								          (m.m_model like concat('%',' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') 
										                                                                                                      or m.m_model like concat('%',' ',m_word1)) or m.m_model like m_word2)) or
										  --to handle the s in the end of either word1 or word 2

										  (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word2) or
				                           m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word2,' ','%') or
				  						   m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word2) or
										   m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word2,' ','%') or
										   m.m_model like concat(m_word1,' ',substring(m_word2,1,len(m_word2)-1)) or
				                           m.m_model like concat(m_word1,' ',substring(m_word2,1,len(m_word2)-1),' ','%') or
				  						   m.m_model like concat('%',' ',m_word1,' ',substring(m_word2,1,len(m_word2)-1)) or
										   m.m_model like concat('%',' ',m_word1,' ',substring(m_word2,1,len(m_word2)-1),' ','%') or
										   m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',substring(m_word2,1,len(m_word2)-1)) or
									      (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2)) or m.m_model like substring(m_word1,1,len(m_word1)-1) ) or 
									      (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1))) or m.m_model like substring(m_word1,1,len(m_word1)-1) ) or 
									   -- (m.m_model like concat(m_word1,' ','%') and ((m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2)) or (m.m_model like m_word1 or m.m_model like concat(m_word1,' ','%') )) or 
									      (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%')) or m.m_model like substring(m_word1,1,len(m_word1)-1) ) or  
										  (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%')) or m.m_model like substring(m_word1,1,len(m_word1)-1) ) or 
									   -- (m.m_model like concat('%',' ',m_word1) and ((m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%')) or (m.m_model like m_word1 or m.m_model like concat('%',' ',m_word1) ) ) or  
								          (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') 
										                                                                               or  m.m_model like concat('%',' ',m_word2)) or m.m_model like substring(m_word1,1,len(m_word1)-1) ) or
										  (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') 
										                                                                               or  m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1))) or m.m_model like substring(m_word1,1,len(m_word1)-1) ) or
									   -- (m.m_model like concat('%',' ',m_word1,' ','%') and  ((m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') 
										                                                    --or m.m_model like concat('%',' ',m_word2)) or (m.m_model like m_word1 or m.m_model like concat('%',' ',m_word1,' ','%'))) or
										   m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word1) or
										   m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word1,' ','%')or
										   m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word1) or
										   m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word1,' ','%') or
										   m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',substring(m_word1,1,len(m_word1)-1)) or
									      (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)) or m.m_model like substring(m_word2,1,len(m_word2)-1) )  or
										  (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))) or m.m_model like substring(m_word2,1,len(m_word2)-1) )  or
									      (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%')) or m.m_model like substring(m_word2,1,len(m_word2)-1) ) or  
										  (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%')) or m.m_model like substring(m_word2,1,len(m_word2)-1) ) or  
								          (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') 
										                                                                                or m.m_model like concat('%',' ',m_word1)) or m.m_model like substring(m_word2,1,len(m_word2)-1)) or
										  (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') 
										                                                                                or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))) or m.m_model like substring(m_word2,1,len(m_word2)-1))) )) or

			       --for names with 3 words
				  (nn.m_lastrec = 3 and ( (m.m_model like concat(m_word1,' ',m_word2) or
								           m.m_model like concat(m_word1,' ',m_word2,' ','%') or                                          
										   m.m_model like concat('%',' ',m_word1,' ',m_word2) or
										   m.m_model like concat('%',' ',m_word1,' ',m_word2,' ','%')) or
                                          (m.m_model like concat(m_word2,' ',m_word1) or
										   m.m_model like concat(m_word2,' ',m_word1,' ','%') or
										   m.m_model like concat('%',' ',m_word2,' ',m_word1) or
										   m.m_model like concat('%',' ',m_word2,' ',m_word1,' ','%')) or
										  (m.m_model like concat(m_word1,' ',m_word3)  or
										   m.m_model like concat(m_word1,' ',m_word3,' ','%') or
										   m.m_model like concat('%',' ',m_word1,' ',m_word3) or
										   m.m_model like concat('%',' ',m_word1,' ',m_word3,' ','%')) or
										  (m.m_model like concat(m_word3,' ',m_word1) or
										   m.m_model like concat(m_word3,' ',m_word1,' ','%') or
										   m.m_model like concat('%',' ',m_word3,' ',m_word1) or
										   m.m_model like concat('%',' ',m_word3,' ',m_word1,' ','%')) or 
										  (m.m_model like concat(m_word2,' ',m_word3) or
										   m.m_model like concat(m_word3,' ',m_word2) or
										   m.m_model like concat(m_word2,' ',m_word3,'%') or
	                                       m.m_model like concat(m_word3,' ',m_word2,'%') or
										   m.m_model like concat(m_word2,' ',m_word3,' ','%') or
										   m.m_model like concat(m_word3,' ',m_word2,' ','%')) or
										  (m.m_model like m_word1 ) or (m.m_model like m_word2 ) or  (m.m_model like m_word3 ) or 
									  	  (m.m_model like concat(m_word1,' ','%') and  ((m.m_model like concat('%',' ',m_word2,' ','%') and m.m_model like concat('%',' ',m_word3,' ','%')) or (m.m_model like m_word1 )) ) or
										  (m.m_model like concat('%',' ',m_word3) and  ((m.m_model like concat('%',' ',m_word1,' ','%') and m.m_model like concat('%',' ',m_word2,' ','%')) or (m.m_model like m_word3))) or
										  (m.m_model like concat(m_word2,' ',m_word3,' ','%') and ( (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) )or (m.m_model like concat(m_word2,' ',m_word3) or m.m_model like concat(m_word3,' ',m_word2)) ) ) or
										  (m.m_model like concat('%',' ',m_word2,' ',m_word3,' ','%') and ((m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat(m_word1,' ','%')) or 
										  (m.m_model like concat(m_word2,' ',m_word3) or m.m_model like concat(m_word3,' ',m_word2)) )) or 
															
										  --to handle 's' in the end of word2
										  (m.m_model like concat(m_word1,' ',substring(m_word2,1,len(m_word2)-1)) or
								           m.m_model like concat(m_word1,' ',substring(m_word2,1,len(m_word2)-1),' ','%') or                                          
										   m.m_model like concat('%',' ',m_word1,' ',substring(m_word2,1,len(m_word2)-1)) or
										   m.m_model like concat('%',' ',m_word1,' ',substring(m_word2,1,len(m_word2)-1),' ','%')) or

                                          (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word1) or
										   m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word1,' ','%') or
										   m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word1) or
										   m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word1,' ','%')) or

										  --to handle 's' in the end of word3
										  (m.m_model like concat(m_word1,' ',substring(m_word3,1,len(m_word3)-1))  or
										   m.m_model like concat(m_word1,' ',substring(m_word3,1,len(m_word3)-1),' ','%') or
										   m.m_model like concat('%',' ',m_word1,' ',substring(m_word3,1,len(m_word3)-1)) or
										   m.m_model like concat('%',' ',m_word1,' ',substring(m_word3,1,len(m_word3)-1),' ','%')) or

										  (m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',m_word1) or
										   m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',m_word1,' ','%') or
										   m.m_model like concat('%',' ',substring(m_word3,1,len(m_word3)-1),' ',m_word1) or
										   m.m_model like concat('%',' ',substring(m_word3,1,len(m_word3)-1),' ',m_word1,' ','%')) or 

										  --to handle 's' at the end of word 3 and  word2 
										  (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word3) or
										   m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',substring(m_word3,1,len(m_word3)-1)) or
										   m.m_model like concat(m_word2,' ',substring(m_word3,1,len(m_word3)-1))) or

										  (m.m_model like concat(m_word3,' ',substring(m_word2,1,len(m_word2)-1)) or
										   m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',substring(m_word2,1,len(m_word2)-1)) or
										   m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',m_word2)) or

										  (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word3,' ','%') or
										   m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',substring(m_word3,1,len(m_word3)-1),' ','%') or
									       m.m_model like concat(m_word2,' ',substring(m_word3,1,len(m_word3)-1),' ','%')) or

										  (m.m_model like concat(m_word3,' ',substring(m_word2,1,len(m_word2)-1),' ','%') or
										   m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',substring(m_word2,1,len(m_word2)-1),' ','%') or
										   m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',m_word2,' ','%')) or

										  (m.m_model like substring(m_word2,1,len(m_word2)-1) ) or  (m.m_model like substring(m_word3,1,len(m_word3)-1) ) or 

										  (m.m_model like concat(m_word1,' ','%') and  ((m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') and m.m_model like concat('%',' ',substring(m_word3,1,len(m_word3)-1),' ','%')) or (m.m_model like m_word1 )) ) or

										  (m.m_model like concat('%',' ',substring(m_word3,1,len(m_word3)-1)) and  ((m.m_model like concat('%',' ',m_word1,' ','%') and m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%')) or 
															                                                        (m.m_model like substring(m_word3,1,len(m_word3)-1)) )) or

										  (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word3,' ','%') and ((m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) )or 
											                                                                                   (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word3) or m.m_model like concat(m_word3,' ',substring(m_word2,1,len(m_word2)-1))))) or

										  (m.m_model like concat(m_word2,' ',substring(m_word3,1,len(m_word3)-1),' ','%') and ((m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) ) or 
															                                                                   (m.m_model like concat(m_word2,' ',substring(m_word3,1,len(m_word3)-1)) or m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',m_word2)))) or

										  (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',substring(m_word3,1,len(m_word3)-1),' ','%') and ((m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) )or 
															                                                                                               (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',substring(m_word3,1,len(m_word3)-1)) or 
																																							m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',substring(m_word2,1,len(m_word2)-1))))) or

										  (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word3,' ','%') and ((m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat(m_word1,' ','%')) or 
											  				                                                                           (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word3) or m.m_model like concat(m_word3,' ',substring(m_word2,1,len(m_word2)-1))))) or

										  (m.m_model like concat('%',' ',m_word2,' ',substring(m_word3,1,len(m_word3)-1),' ','%') and ((m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat(m_word1,' ','%')) or 
											  				                                                                           (m.m_model like concat(m_word2,' ',substring(m_word3,1,len(m_word3)-1)) or m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',m_word2))))  or    
																															 	
										  (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',substring(m_word3,1,len(m_word3)-1),' ','%') and ((m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat(m_word1,' ','%')) or 
															                                                                                                       (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',substring(m_word3,1,len(m_word3)-1)) or m.m_model like concat(substring(m_word3,1,len(m_word3)-1),' ',substring(m_word2,1,len(m_word2)-1)))))      															  																  
																															                                       )) or
				   -- for four words
				   (nn.m_lastrec = 4 and  ((m.m_model like concat(m_word1,' ',m_word2) or
								            m.m_model like concat(m_word1,' ',m_word2,' ','%') or                                          
											m.m_model like concat('%',' ',m_word1,' ',m_word2) or
											m.m_model like concat('%',' ',m_word1,' ',m_word2,' ','%')) or

											--if the first word has 's' in the end
										   (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word2) or
								            m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word2,' ','%') or                                          
											m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word2) or
											m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word2,' ','%')) or
											
											--normal 2 & 1
                                           (m.m_model like concat(m_word2,' ',m_word1) or
											m.m_model like concat(m_word2,' ',m_word1,' ','%') or
											m.m_model like concat('%',' ',m_word2,' ',m_word1) or
											m.m_model like concat('%',' ',m_word2,' ',m_word1,' ','%')) or

										    --to handle 's' 2 & 1
										   (m.m_model like concat(m_word2,' ',substring(m_word1,1,len(m_word1)-1)) or
											m.m_model like concat(m_word2,' ',substring(m_word1,1,len(m_word1)-1),' ','%') or
											m.m_model like concat('%',' ',m_word2,' ',substring(m_word1,1,len(m_word1)-1)) or
											m.m_model like concat('%',' ',m_word2,' ',substring(m_word1,1,len(m_word1)-1),' ','%')) or

                                           --normal 1 & 3
										   (m.m_model like concat(m_word1,' ',m_word3)  or
											m.m_model like concat(m_word1,' ',m_word3,' ','%') or
											m.m_model like concat('%',' ',m_word1,' ',m_word3) or
											m.m_model like concat('%',' ',m_word1,' ',m_word3,' ','%')) or

											--to handle 's' 1 & 3
										   (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word3)  or
											m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word3,' ','%') or
											m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word3) or
											m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word3,' ','%')) or
															
										   --normal 3 & 1
										   --(m.m_model like concat('%',' ',m_word1,' ','%',' ',m_word3,' ','%') and m.m_model like concat('%',m_word2,'%'))) or
										   (m.m_model like concat(m_word3,' ',m_word1) or
											m.m_model like concat(m_word3,' ',m_word1,' ','%') or
											m.m_model like concat('%',' ',m_word3,' ',m_word1) or
											m.m_model like concat('%',' ',m_word3,' ',m_word1,' ','%')) or 

											--to handle 's' 3 & 1
										   (m.m_model like concat(m_word3,' ',substring(m_word1,1,len(m_word1)-1)) or
											m.m_model like concat(m_word3,' ',substring(m_word1,1,len(m_word1)-1),' ','%') or
											m.m_model like concat('%',' ',m_word3,' ',substring(m_word1,1,len(m_word1)-1)) or
											m.m_model like concat('%',' ',m_word3,' ',substring(m_word1,1,len(m_word1)-1),' ','%')) or 

											--normal 2 & 4
                                           (m.m_model like concat(m_word2,' ',m_word4)  or		   
										   (m.m_model like concat(m_word2,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))) or
										   (m.m_model like concat('%',' ',m_word2,' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word2,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or

										   --to handle 's' 2 & 4
										   (m.m_model like concat(m_word2,' ',substring(m_word4,1,len(m_word4)-1))  or		   
										   (m.m_model like concat(m_word2,' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))) or
										   (m.m_model like concat(m_word2,' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)))) or
										   (m.m_model like concat('%',' ',m_word2,' ',substring(m_word4,1,len(m_word4)-1)) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word2,' ',substring(m_word4,1,len(m_word4)-1)) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										   (m.m_model like concat('%',' ',m_word2,' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))) or
										   (m.m_model like concat('%',' ',m_word2,' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') 
											 			                                                                             or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or
                                                           
										   --normal 4 & 2
										   (m.m_model like concat(m_word4,' ',m_word2)  or
										   (m.m_model like concat(m_word4,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))) or
										   (m.m_model like concat('%',' ',m_word4,' ',m_word2) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word4,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or

										   --to handle s 4 & 2 
										   (m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',m_word2)  or
										   (m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))) or
										   (m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',m_word2,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)))) or
										   (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word2) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%'))) or
										   (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word2) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										   (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
										   (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word2,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or

										   --normal 3 & 4
                                           (m.m_model like concat(m_word3,' ',m_word4)  or
										  	m.m_model like concat(m_word3,' ',m_word4,' ','%') or
										   (m.m_model like concat('%',' ',m_word3,' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') )) or
										   (m.m_model like concat('%',' ',m_word3,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or

										  --to handle s 3 & 4
										   (m.m_model like concat(m_word3,' ',substring(m_word4,1,len(m_word4)-1))  or
											m.m_model like concat(m_word3,' ',substring(m_word4,1,len(m_word4)-1),' ','%') or
										   (m.m_model like concat('%',' ',m_word3,' ',substring(m_word4,1,len(m_word4)-1)) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') )) or
										   (m.m_model like concat('%',' ',m_word3,' ',substring(m_word4,1,len(m_word4)-1)) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') )) or
										   (m.m_model like concat('%',' ',m_word3,' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))) or
										   (m.m_model like concat('%',' ',m_word3,' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or

										  --normal 4 & 3
										   (m.m_model like concat(m_word4,' ',m_word3)  or
										 	m.m_model like concat(m_word4,' ',m_word3,' ','%') or
										   (m.m_model like concat('%',' ',m_word4,' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word4,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or

										   --to handle s 4 & 3
										   (m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',m_word3)  or
										 	m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',m_word3,' ','%') or
										   (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%'))) or
                                           (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word3) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										   (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))) or
										   (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word3,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or

										   --normal 2 & 3
										   (m.m_model like concat(m_word2,' ',m_word3)  or
										   (m.m_model like concat(m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word4,' ','%') or
											                                                        m.m_model like concat('%',' ',m_word1) or m.m_model like concat('%',' ',m_word4))) or														 
										   (m.m_model like concat('%',' ',m_word2,' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word4,' ','%') or
											                                                        m.m_model like concat(m_word1,' ','%') or m.m_model like concat(m_word4,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word4,' ','%') or
											                                                                m.m_model like concat(m_word1,' ','%') or m.m_model like concat(m_word4,' ','%') or
											                                                                m.m_model like concat('%',' ',m_word1) or m.m_model like concat('%',' ',m_word4)))) or
                                                           
										   --to handle s 2 & 3
										   (m.m_model like concat(m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ','%') or
										                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1)))) or														 
										   (m.m_model like concat('%',' ',m_word2,' ',m_word3) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ','%') or
											                                                        m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ','%'))) or
										   (m.m_model like concat('%',' ',m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ','%') or
											                                                                m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ','%') or
											                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1))))) or
                                          --normal 3 & 2
										   (m.m_model like concat(m_word3,' ',m_word2)  or
										   (m.m_model like concat(m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word4,' ','%') or
											                                                        m.m_model like concat('%',' ',m_word1) or m.m_model like concat('%',' ',m_word4))) or
										   (m.m_model like concat('%',' ',m_word3,' ',m_word2) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word4,' ','%') or
											                                                        m.m_model like concat(m_word1,' ','%') or m.m_model like concat(m_word4,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word4,' ','%') or
											                                                                m.m_model like concat(m_word1,' ','%') or m.m_model like concat(m_word4,' ','%') or
											  															    m.m_model like concat('%',' ',m_word1) or m.m_model like concat('%',' ',m_word4))))  or

                                           --to handle s 3 & 2
										   (m.m_model like concat(m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ','%') or
											                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1)))) or
										   (m.m_model like concat('%',' ',m_word3,' ',m_word2) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ','%') or
											                                                        m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(m_word4,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ','%') or
											                                                                m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ','%') or
											  															    m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1)))))  or
										   --normal 1 & 4											
    									   (m.m_model like concat(m_word1,' ',m_word4)  or
											m.m_model like concat(m_word1,' ',m_word4,' ','%') or
										   (m.m_model like concat(m_word1,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                                                        m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or														 
										   (m.m_model like concat('%',' ',m_word1,' ',m_word4) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
										                                                            m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word1,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                                                                m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%') or
											                                                                m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))))  or

                                           --to handle s 1 & 4
										   (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word4)  or
											m.m_model like concat(m_word1,' ',substring(m_word4,1,len(m_word4)-1))  or
											m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',substring(m_word4,1,len(m_word4)-1))  or
											m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word4,' ','%') or
											m.m_model like concat(m_word1,' ',substring(m_word4,1,len(m_word4)-1),' ','%') or
											m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',substring(m_word4,1,len(m_word4)-1),' ','%') or

										   (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                       	                                                            m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or		
                                           (m.m_model like concat(m_word1,' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
										   	                                                                                    m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or	
										   (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											            	                                                                                                m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or		
																													 																												 												 
										   (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word4) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
												                                                                                m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word1,' ',substring(m_word4,1,len(m_word4)-1)) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
												                                                                                m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%'))) or
										   (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',substring(m_word4,1,len(m_word4)-1)) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											          	                                                                                                    m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%'))) or

										   (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											       	                                                                                    m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%') or
												                                                                                        m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or
									       (m.m_model like concat('%',' ',m_word1,' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											       	                                                                                    m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%') or
												                                                                                        m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or
										   (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',substring(m_word4,1,len(m_word4)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
												                                                                                                                    m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%') or
												                                                                                                                    m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))))  or
                                           --normal search 4 & 1
										   (m.m_model like concat(m_word4,' ',m_word1)  or
											m.m_model like concat(m_word4,' ',m_word1,' ','%') or
										   (m.m_model like concat(m_word4,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                                                        m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or														 
										   (m.m_model like concat('%',' ',m_word4,' ',m_word1) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
										                                                            m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%'))) or
										   (m.m_model like concat('%',' ',m_word4,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                                                                m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%') or
											                                                                m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3)))) or

                                           --to handle s 4 & 1
										  (m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',m_word1)  or
										   m.m_model like concat(m_word4,' ',substring(m_word1,1,len(m_word1)-1)) or
   										   m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',substring(m_word1,1,len(m_word1)-1)) or

										   m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',m_word1,' ','%') or
										   m.m_model like concat(m_word4,' ',substring(m_word1,1,len(m_word1)-1),' ','%') or
										   m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',substring(m_word1,1,len(m_word1)-1),' ','%') or

									      (m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
										  	                                                                                   m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or	
										  (m.m_model like concat(m_word4,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											  	                                                                               m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or	
										  (m.m_model like concat(substring(m_word4,1,len(m_word4)-1),' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
												                                                                                                           m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or	
																													 													 
										  (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word1) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                                                                                   m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%'))) or
										  (m.m_model like concat('%',' ',m_word4,' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                                                                                   m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%'))) or
										  (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                                                                                                               m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%'))) or

										  (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
										   	                                                                                           m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%') or
															                                                                           m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or
										  (m.m_model like concat('%',' ',m_word4,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                                                                                           m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%') or
												                                                                                       m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3))) or
										  (m.m_model like concat('%',' ',substring(m_word4,1,len(m_word4)-1),' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%') or
											                                                                                                                       m.m_model like concat(m_word2,' ','%') or m.m_model like concat(m_word3,' ','%') or
												                                                                                                                   m.m_model like concat('%',' ',m_word2) or m.m_model like concat('%',' ',m_word3)))) or

										  (m.m_model like m_word1) or 
										  --to handle s 1
										  (m.m_model like substring(m_word1,1,len(m_word1)-1)) )) or
																							                                               							 
																																	
				  --for names with 5 words
				  (nn.m_lastrec = 5 and  ((m.m_model like concat(m_word1,' ',m_word2) or
					                       m.m_model like concat(m_word1,' ',m_word2,' ','%') or                                          
					   				       m.m_model like concat('%',' ',m_word1,' ',m_word2) or
										   m.m_model like concat('%',' ',m_word1,' ',m_word2,' ','%')) or
										   --to handle s in word 1
										  (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word2) or
								           m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word2,' ','%') or                                          
										   m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word2) or
										   m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word2,' ','%')) or

                                          (m.m_model like concat(m_word2,' ',m_word1) or
										   m.m_model like concat(m_word2,' ',m_word1,' ','%') or
										   m.m_model like concat('%',' ',m_word2,' ',m_word1) or
										   m.m_model like concat('%',' ',m_word2,' ',m_word1,' ','%')) or
										  --to handle s in word 1
										  (m.m_model like concat(m_word2,' ',substring(m_word1,1,len(m_word1)-1)) or
										   m.m_model like concat(m_word2,' ',substring(m_word1,1,len(m_word1)-1),' ','%') or
										   m.m_model like concat('%',' ',m_word2,' ',substring(m_word1,1,len(m_word1)-1)) or
										   m.m_model like concat('%',' ',m_word2,' ',substring(m_word1,1,len(m_word1)-1),' ','%')) or

                                          (m.m_model like concat(m_word1,' ',m_word3)  or
										   m.m_model like concat(m_word1,' ',m_word3,' ','%') or
										   m.m_model like concat('%',' ',m_word1,' ',m_word3) or
										   m.m_model like concat('%',' ',m_word1,' ',m_word3,' ','%')) or
										  --to handle s
										  (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word3)  or
										   m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word3,' ','%') or
										   m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word3) or
										   m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word3,' ','%')) or
															
										  --(m.m_model like concat('%',' ',m_word1,' ','%',' ',m_word3,' ','%') and m.m_model like concat('%',m_word2,'%'))) or
										  (m.m_model like concat(m_word3,' ',m_word1) or
										   m.m_model like concat(m_word3,' ',m_word1,' ','%') or
										   m.m_model like concat('%',' ',m_word3,' ',m_word1) or
										   m.m_model like concat('%',' ',m_word3,' ',m_word1,' ','%')) or 
										  --to handle s
										  (m.m_model like concat(m_word3,' ',substring(m_word1,1,len(m_word1)-1)) or
										   m.m_model like concat(m_word3,' ',substring(m_word1,1,len(m_word1)-1),' ','%') or
										   m.m_model like concat('%',' ',m_word3,' ',substring(m_word1,1,len(m_word1)-1)) or
										   m.m_model like concat('%',' ',m_word3,' ',substring(m_word1,1,len(m_word1)-1),' ','%')) or 

                                          (m.m_model like concat(m_word2,' ',m_word4)  or
										  (m.m_model like concat(m_word2,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))) or
										  (m.m_model like concat('%',' ',m_word2,' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%'))) or
										  (m.m_model like concat('%',' ',m_word2,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%')or 
										                                                                   m.m_model like concat(m_word1,' ','%') or 
											   															   m.m_model like concat('%',' ',m_word1)))) or
										  --to handle s
										 ((m.m_model like concat(m_word2,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)))) or
										  (m.m_model like concat('%',' ',m_word2,' ',m_word4) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										  (m.m_model like concat('%',' ',m_word2,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')or 
										                                                                   m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or 
											  															   m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) ) ) ) or

										  (m.m_model like concat(m_word4,' ',m_word2)  or
										  (m.m_model like concat(m_word4,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))) or
										  (m.m_model like concat('%',' ',m_word4,' ',m_word2) and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%'))) or
										  (m.m_model like concat('%',' ',m_word4,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or
										 --to handle s
										 ((m.m_model like concat(m_word4,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)))) or
										  (m.m_model like concat('%',' ',m_word4,' ',m_word2) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										  (m.m_model like concat('%',' ',m_word4,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') 
										                                                                or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') 
											  														    or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or
															
                                          (m.m_model like concat(m_word3,' ',m_word4)  or
										   m.m_model like concat(m_word3,' ',m_word4,' ','%') or
										  (m.m_model like concat('%',' ',m_word3,' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%')))  or
										  (m.m_model like concat('%',' ',m_word3,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or
										  --to handle s
										 ((m.m_model like concat('%',' ',m_word3,' ',m_word4) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%')))  or
										  (m.m_model like concat('%',' ',m_word3,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or 
										                                                                   m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or 
											  															   m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or

  									     (m.m_model like concat(m_word4,' ',m_word3)  or
										  m.m_model like concat(m_word4,' ',m_word3,' ','%') or
										 (m.m_model like concat('%',' ',m_word4,' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%'))) or
										 (m.m_model like concat('%',' ',m_word4,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1))))  or
										 --to handle s
										((m.m_model like concat('%',' ',m_word4,' ',m_word3) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										 (m.m_model like concat('%',' ',m_word4,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')or 
										                                                                  m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or 
										 																  m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)))))  or

										 (m.m_model like concat(m_word4,' ',m_word5)  or
										  m.m_model like concat(m_word4,' ',m_word5,' ','%') or
										 (m.m_model like concat('%',' ',m_word4,' ',m_word5) and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%'))) or
										 (m.m_model like concat('%',' ',m_word4,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or
										 --to handle s
										((m.m_model like concat('%',' ',m_word4,' ',m_word5) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										 (m.m_model like concat('%',' ',m_word4,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or 
															                                              m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or 
																										  m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or

 									 	 (m.m_model like concat(m_word5,' ',m_word4)  or
										  m.m_model like concat(m_word5,' ',m_word4,' ','%') or
										 (m.m_model like concat('%',' ',m_word5,' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%'))) or
										 (m.m_model like concat('%',' ',m_word5,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or
										--to handle s
										((m.m_model like concat('%',' ',m_word5,' ',m_word4) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										 (m.m_model like concat('%',' ',m_word5,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') 
										                                                               or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') 
											 														   or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or
														
										 (m.m_model like concat(m_word3,' ',m_word5)  or
										  m.m_model like concat(m_word3,' ',m_word5,' ','%') or
										 (m.m_model like concat('%',' ',m_word3,' ',m_word5) and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%'))) or
										 (m.m_model like concat('%',' ',m_word3,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or
										 --to handle s
										((m.m_model like concat('%',' ',m_word3,' ',m_word5) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										 (m.m_model like concat('%',' ',m_word3,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or 
										                                                                  m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or 
											 															  m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or

										 (m.m_model like concat(m_word5,' ',m_word3)  or
										  m.m_model like concat(m_word5,' ',m_word3,' ','%') or
										 (m.m_model like concat('%',' ',m_word5,' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%')or m.m_model like concat(m_word1,' ','%'))) or
										 (m.m_model like concat('%',' ',m_word5,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1)))) or
										--to handle s
										((m.m_model like concat('%',' ',m_word5,' ',m_word3) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%')or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%'))) or
										 (m.m_model like concat('%',' ',m_word5,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or 
										                                                                  m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or 
										 																  m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1))))) or
															
										(m.m_model like concat(m_word2,' ',m_word3)  or
									    (m.m_model like concat(m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or 
									                                                             m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																								 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5))) or	
									    --to handle s
									    (m.m_model like concat(m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or 
										                                                        m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																							    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5))) or	
																													 													 
									    (m.m_model like concat('%',' ',m_word2,' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
										  					                                     m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																			  				     m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%'))) or
									    --to handle s
										(m.m_model like concat('%',' ',m_word2,' ',m_word3) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
										                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%'))) or
																													 														      
									    (m.m_model like concat('%',' ',m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or 
										                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or 
																										 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5))) or	--cut one)
										--to handle s
										(m.m_model like concat('%',' ',m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or 
										                                                                 m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or 
																										 m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or 
										                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or 
																										 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5)))) or	
																															 																 										                                                                
										(m.m_model like concat(m_word3,' ',m_word2)  or
									    (m.m_model like concat(m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or 
										                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																								 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5))) or	
                                        --to handle s
										(m.m_model like concat(m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or 
									                                                             m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or 
										                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																								 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5))) or	

										(m.m_model like concat('%',' ',m_word3,' ',m_word2) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
										                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
										 													     m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%'))) or
                                         --to handle s
										(m.m_model like concat('%',' ',m_word3,' ',m_word2) and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or 
										                                                         m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
										                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%'))) or

										(m.m_model like concat('%',' ',m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or 
										                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or 
																										 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5))) or --cut one	
										--to handle s
										(m.m_model like concat('%',' ',m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or 
										                                                                 m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or 
																										 m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or 
										                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or 
																										 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5)))) or																	 								
    									(m.m_model like concat(m_word1,' ',m_word5)  or
										-- m.m_model like concat(m_word1,' ',m_word5,' ','%') or
										(m.m_model like concat(m_word1,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                         m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or														 
										(m.m_model like concat('%',' ',m_word1,' ',m_word5) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                         m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
										(m.m_model like concat('%',' ',m_word1,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                 m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3)or 
																										 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))))  or 
                                        --to handle s
										(m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word5)  or
										 m.m_model like concat(m_word1,' ',substring(m_word5,1,len(m_word5)-1))  or
										 m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',substring(m_word5,1,len(m_word5)-1))  or
										-- m.m_model like concat(m_word1,' ',m_word5,' ','%') or
										(m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                                     m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								                             m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or		
                                        (m.m_model like concat(m_word1,' ',substring(m_word5,1,len(m_word5)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                                     m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								                             m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
										(m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',substring(m_word5,1,len(m_word5)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                                                                 m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
										(m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',m_word5) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                                     m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										  													                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
										(m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',m_word5) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                                     m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										 														                             m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
										(m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',m_word5) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                                     m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										 														                             m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
										(m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                         m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3)or 
																															         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4)))or
										(m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										  					                                                                         m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3)or 
																														        	 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or
										(m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                         m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3)or 
																															         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))))  or
                                        --word 5 & 1 
										(m.m_model like concat(m_word5,' ',m_word1)  or
										-- m.m_model like concat(m_word5,' ',m_word1,' ','%') or
									    (m.m_model like concat(m_word5,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                         m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or														 
									    (m.m_model like concat('%',' ',m_word5,' ',m_word1) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                         m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
									    (m.m_model like concat('%',' ',m_word5,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                 m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or 
																										 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4)))) or
                                                           
										--to handle s 
										(m.m_model like concat(substring(m_word5,1,len(m_word5)-1),' ',substring(m_word1,1,len(m_word1)-1))  or
										 m.m_model like concat(m_word5,' ',substring(m_word1,1,len(m_word1)-1))  or
										 m.m_model like concat(substring(m_word5,1,len(m_word5)-1),' ',substring(m_word1,1,len(m_word1)-1))  or
										 -- m.m_model like concat(m_word5,' ',m_word1,' ','%') or

										(m.m_model like concat(substring(m_word5,1,len(m_word5)-1),' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										  				                                                                     m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																													         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or			
										(m.m_model like concat(m_word5,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                 m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																													         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
										(m.m_model like concat(substring(m_word5,1,len(m_word5)-1),' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                                             m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																													                                     m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
																													 														 														 											 
										(m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',m_word1) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                 m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																													         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
                                        (m.m_model like concat('%',' ',m_word5,' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                 m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																													         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	
                                        (m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                                             m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																													                                     m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or	

										(m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                         m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or 
																															         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or
										(m.m_model like concat('%',' ',m_word5,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                         m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or 
																															         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) or
									    (m.m_model like concat('%',' ',substring(m_word5,1,len(m_word5)-1),' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                                                     m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or 
																															                                     m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))) ) or
									    (m.m_model like m_word1) or (m.m_model like substring(m_word1,1,len(m_word1)-1)) )) or

                 --for names with 6 words 
				 --each line of the following script handles normal search and for handling s at the end for word1  
				 (nn.m_lastrec = 6 and ((m.m_model like concat(m_word1,' ',m_word2) or	
								        --to handle s
										 m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word2) or
										 m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',substring(m_word2,1,len(m_word2)-1)) or		
										 m.m_model like concat(m_word1,' ',substring(m_word2,1,len(m_word2)-1))  or											                          
										 --if the name is heavy duty Morse taper drilling machine, word 1 and word2 plus any one of the other words should be present to get matching name
										 --word1 & word 2 at the beginning
								         (m.m_model like concat(m_word1,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
								 		                                                          m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																								  m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																								  m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or   
                                         --to handle s word1 & word 2 at the beginning
										 (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                      m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
										 														                              m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													          m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or  
                                         (m.m_model like concat(m_word1,' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                      m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
										 														                              m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													          m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                         (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                                                  m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
										 														                                                          m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													                                      m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
										--word1	& word2 at the end													  																													                                        
										(m.m_model like concat('%',' ',m_word1,' ',m_word2) and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
										                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								 m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                        --to handle s - word1 & word2 at the end	
										(m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word2) and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
										                                                                                     m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								                             m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								                             m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                        (m.m_model like concat('%',' ',m_word1,' ',substring(m_word2,1,len(m_word2)-1)) and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
										                                                                                     m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								                             m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								                             m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                        (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',substring(m_word2,1,len(m_word2)-1)) and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
										                                                                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								                                                         m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								                                                         m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or

                                        --word 1 and word2 in the center
                                        (m.m_model like concat('%',' ',m_word1,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																										 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										 m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                        --to handle s - word 1 and word2 in the center
                                        (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                             m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																										                             m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										                             m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or --here )
                                        (m.m_model like concat('%',' ',m_word1,' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                             m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																										                             m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										                             m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) ))or --here )
                                        (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																										                                                         m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										                                                         m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )))or

                                        --word 2 & 1
                                        (m.m_model like concat(m_word2,' ',m_word1) or
										--to handle s - word 2 & 1
										 m.m_model like concat(m_word2,' ',substring(m_word1,1,len(m_word1)-1)) or
                                         m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word1) or
										 m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',substring(m_word1,1,len(m_word1)-1)) or
										 --word 2 and word 1 in the beginning
										(m.m_model like concat(m_word2,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																								 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																								 m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or   
	                                    --to handle s - word 2 and word 1 in the beginning 
	                                    (m.m_model like concat(m_word2,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
															                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																													         m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													         m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or		
                                        (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                     m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																								                             m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																								                             m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or		
                                        (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																								                                                         m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																								                                                         m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or		

										--word 2 and word 1 at the end														 																										      
										(m.m_model like concat('%',' ',m_word2,' ',m_word1) and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
										                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								 m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                        --to handle s -  word 2 and word 1 at the end	
										(m.m_model like concat('%',' ',m_word2,' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
										                                                                                     m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								                             m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								                             m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                        (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word1) and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
										                                                                                     m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								                             m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								                             m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                        (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
										                                                                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																								                                                         m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								                                                         m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                                            
										--word 2 and word 1 in the center
										(m.m_model like concat('%',' ',m_word2,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                 m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																										 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
										  															     m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) or
										--to handle s - word 2 and word 1 in the center																 
										(m.m_model like concat('%',' ',m_word2,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                             m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																										                             m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										                             m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) or --here )
                                        (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                             m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																										                             m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										                             m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) or --here )
                                        (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										                                                                                                                         m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																										                                                         m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										                                                         m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or

                                        --word 1 & 3
                                        (m.m_model like concat(m_word1,' ',m_word3)  or
										--to handle s -word 1 & 3
										m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word3) or
										--word 1 & word 3 at the beginning
									   (m.m_model like concat(m_word1,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
															                                    m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																								m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																								m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
									    --to handle s - word 1 & word 3 at the beginning
									   (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										  						                                                            m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
															                                                                m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																													        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or				
									   --word 1 and word3 at the end																					 										  
									   (m.m_model like concat('%',' ',m_word1,' ',m_word3) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
										                                                        m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
										                                                        m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
										 													    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                       --to handle s - word 1 and word3 at the end
									   (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word3) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
										                                                                                    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
										                                                                                    m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																							                                m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																													        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                       --word 1 and word 3 in the center
									   (m.m_model like concat('%',' ',m_word1,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
										                                                                m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
										 															    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) or
										--to handle s - word 1 and word 3 in the center																 
									   (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                                            m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
										                                                                                            m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																									                                m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																															        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or

									   --word 3 & 1 
									   (m.m_model like concat(m_word3,' ',m_word1) or
									   --to handle s -  word 3 & 1
									    m.m_model like concat(m_word3,' ',substring(m_word1,1,len(m_word1)-1)) or
									   --word 3 and word 1 in the beginning
									   (m.m_model like concat(m_word3,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                        m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
										                                                        m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																								m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																								m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                       --to handle s -word 3 and word 1 in the beginning
									   (m.m_model like concat(m_word3,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
															                                                                m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
															                                                                m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																													        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                       --word3 and word 1 at the end
									   (m.m_model like concat('%',' ',m_word3,' ',m_word1) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
									                                                            m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
										                                                        m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																							    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                       --to handle s -word3 and word 1 at the end
									   (m.m_model like concat('%',' ',m_word3,' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
										                                                                                    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
										                                                                                    m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																							                                m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																													        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                       --word3 and word1 in the center
									   (m.m_model like concat('%',' ',m_word3,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									                                                                    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
										                                                                m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
										 														        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) or
									   --to handle s -  word3 and word1 in the center																
									   (m.m_model like concat('%',' ',m_word3,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										                                                                                            m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
										                                                                                            m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
										 														                                    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																															        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or

                                       --Word 2 & 4
									   (m.m_model like concat(m_word2,' ',m_word4)  or
									   --to handle s -Word 2 & 4 
										m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word4)  or
									   --word 2 & word 4 in the beginning
									   (m.m_model like concat(m_word2,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
										                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
										                                                        m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																								m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                       --to handle s --word 2 & word 4 in the beginning
									   (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
										                                                                                    m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
															                                                                m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																													        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                       --word 2 and word 4 at the end
									   (m.m_model like concat('%',' ',m_word2,' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
										                                                        m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
										  													    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                       --to handle s --word 2 and word 4 at the end
									   (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
										                                                                                    m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
										                                                                                    m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
																							                                m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																													        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
									   --word 2 and word 4 in the center
									   (m.m_model like concat('%',' ',m_word2,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
										                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
										                                                                m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) or
									   --to handle s - word 2 and word 4 in the center																
									   (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
										                                                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
										                                                                                            m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																								                                    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																															        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or
									   --word 4 & 2
									   (m.m_model like concat(m_word4,' ',m_word2)  or
									   --to handle s  - -word 4 & 2
										m.m_model like concat(m_word4,' ',substring(m_word2,1,len(m_word2)-1))  or
										--word 4 and word 2 in the beginning
									   (m.m_model like concat(m_word4,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
										                                                        m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										               										    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																								m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                       --to handle s - word 4 and word 2 in the beginning
									   (m.m_model like concat(m_word4,' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
										                                                                                    m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
										                                                                                    m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																							                                m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                       --word 4 and word 2 at the end
									   (m.m_model like concat('%',' ',m_word4,' ',m_word2) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
										                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
										                                                        m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
																							    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																								m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                       --to handle s--word 4 and word 2 at the end
									   (m.m_model like concat('%',' ',m_word4,' ',substring(m_word2,1,len(m_word2)-1)) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
										                                                                                    m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
										                                                                                    m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
																							                                m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																										                    m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                       --to handle word4 and word 2 in the center
									   (m.m_model like concat('%',' ',m_word4,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
										                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
										                                                                m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																									    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) or
									   --to handle s -word4 and word 2 in the center																
									   (m.m_model like concat('%',' ',m_word4,' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
										                                                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
										                                                                                            m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
										  														                                    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																															        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or
									   --word 3 & 4 
                                       (m.m_model like concat(m_word3,' ',m_word4)  or
									   --word 3 and word 4 in the beginning and also handle s in word 1 and word 2
									   (m.m_model like concat(m_word3,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
										                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																								m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																								m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																								m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                                           
                                      --word 3 & word 4 at the end and also handle s in the word 1 and word 2
									  (m.m_model like concat('%',' ',m_word3,' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                           m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                           m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
																							   m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
																							   m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																							   m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                                          
                                     --word3 and word 4 in the center - and also handle s in the word 1 and word 2
									 (m.m_model like concat('%',' ',m_word3,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                  m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                  m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
										  															  m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																									  m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																									  m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or
															
								 	--word 4 & 3
									(m.m_model like concat(m_word4,' ',m_word3)  or
									--word 4 & word 3 in the beginning and also handle s in word1 and word 2
									(m.m_model like concat(m_word4,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                         m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                         m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																							 m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																					         m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
								   														     m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                                             
                                    --word 4 and word 3 at the end and also handle s in word 1 and word 2
									(m.m_model like concat('%',' ',m_word4,' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                         m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                         m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
									  													     m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
																							 m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																							 m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                                           
                                    --word 4 and word 3 in the center and also handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word4,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									 															    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																									m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																									m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or
														
								   --word 4 & 5
								   (m.m_model like concat(m_word4,' ',m_word5)  or
								   --word 4 and word 5 in the beginning and handle s in word 1 and word 2
								   (m.m_model like concat(m_word4,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																						    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																							m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                                            
                                   --word 4 and word 5 in the end and also handle s in the word 1 and word 2
								   (m.m_model like concat('%',' ',m_word4,' ',m_word5) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
																						    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
																							m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                                           
                                   --word 4 and word 5 in the center and also handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word4,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									    														    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																									m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																									m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or
															
                                   --word 5 & 4
								   (m.m_model like concat(m_word5,' ',m_word4)  or
								   --word 5 and word 4 in the beginning and handle s in word and word 2
								   (m.m_model like concat(m_word5,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
															                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
															                                m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																							m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																							m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                                           
                                   --word 5 and word 4 in the end and handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word5,' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
									 													    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
																							m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                                           
								   --word 5 and word 4 in the center and handle s in word 1 and word 2														               
								   (m.m_model like concat('%',' ',m_word5,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																								    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																									m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																									m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or
															
							       --word 4 & 6
								   (m.m_model like concat(m_word4,' ',m_word6)  or
								   --word 4 and word 6 in the beginning and handle s in word 1 and word 2
								   (m.m_model like concat(m_word4,' ',m_word6,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																						    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																							m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																							m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) )) or
                                                            
                                   --word 4 and word 6 at the end and handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word4,' ',m_word6) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
									 													    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
																							m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																							m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') )) or
                                                            
                                   --word 4 and word 6 in the center and handle s in word1 and word 2
								   (m.m_model like concat('%',' ',m_word4,' ',m_word6,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																								    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																									m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																									m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3)))) or
															
                                   --word 6 & 4
								   (m.m_model like concat(m_word6,' ',m_word4)  or
								   --word 6 and word 4 in the beginning and handle s in word 1 and word 2
								   (m.m_model like concat(m_word6,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									 													    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																							m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																							m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) )) or
                                                            
                                   --word 6 and word 4 at the end and handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word6,' ',m_word4) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
									 													    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
																							m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																							m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') )) or
                                                            
                                   --word 6 and word 4 and handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word6,' ',m_word4,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																								    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																									m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																									m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3)))) or
															
								   --word 3 & 5
								   (m.m_model like concat(m_word3,' ',m_word5)  or
								   --word 3 and word 5 in the beginning and handle s in word 1 and word 2
								   (m.m_model like concat(m_word3,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									  													    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																							m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                                          
                                   --word 3 & word 5 and handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word3,' ',m_word5) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
																					        m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
																							m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                                          
                                   --word 3 and word 5 and handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word3,' ',m_word5,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																								    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																									m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																									m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or
															
                                   --word 5 & 3
								   (m.m_model like concat(m_word5,' ',m_word3)  or
								   --word 5 and word 3 in the beginning and handle s in word 1 and word 2
								   (m.m_model like concat(m_word5,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									 													    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																							m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or
                                                           
                                   --word 5 and word 3 at the end and handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word5,' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                        m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
									  													    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
																							m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                                           
                                   --word 5 and word 3 in the center and handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',m_word5,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									  															    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
																									m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																									m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or
															
								   --word 2 & 3
								   (m.m_model like concat(m_word2,' ',m_word3)  or
								   --to handle s in word 2
								    m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word3)  or
								   --word 2 and word 3 in the beginning and handle s in word 1 --here
								   (m.m_model like concat(m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
															                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
															                                m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																							m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or		
								   --Word 2 and word 3 in the beginning and handle s in word 1 word 2	
								   (m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                                    m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                                    m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
									 											                                        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													    m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or		
								   --word 2 and word 3 at the end and handle s in word 1																					 												 											 
								   (m.m_model like concat('%',' ',m_word2,' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or  
									                                                        m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																						    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                   --word 2 and word 3 at the end and to handle s in word 1 and word 2
								   (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word3) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                                                    m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                                                    m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																						                                m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																													    m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                   --word 2 and word 3 in the center and to handle s in word 1 
								   (m.m_model like concat('%',' ',m_word2,' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
								                                                                    m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) and
															                                        m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																							        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																									m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) or
                                                            
								   --word 2 and word 3 in the center and to handle s	in word 1 and word 2															 
								   (m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ',m_word3,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                                            m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
									  														                                    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																										                        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) ) or
								   --word 3 & 2 
								   (m.m_model like concat(m_word3,' ',m_word2)  or
								   --to handle s in word 2 
									m.m_model like concat(m_word3,' ',substring(m_word2,1,len(m_word2)-1))  or
								   --word 3 and word 2 in the beginning and to handle s in word 1
								   (m.m_model like concat(m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
								                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                        m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																				            m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or		
                                   --word 3 and word 2 in the beginning and to handle s in word 1 and word 2
								   (m.m_model like concat(m_word3,' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									 						                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
															                                                            m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																										   	            m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																													    m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat('%',' ',m_word6) )) or	
						           --word 3 and word2 at the end and to handle s in word 1 															 	
								   (m.m_model like concat('%',' ',m_word3,' ',m_word2) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
									                                                        m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
									                                                        m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
									 													    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																							m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                   --word 3 and word2 at the end and to handle s in word 1 and word 2 
								   (m.m_model like concat('%',' ',m_word3,' ',substring(m_word2,1,len(m_word2)-1)) and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or
															                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or
															                                                            m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																										                m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or
																										                m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') )) or
                                   --word 3 and word 2 in the center and to handle s in word 1
								   (m.m_model like concat('%',' ',m_word3,' ',m_word2,' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
									 														        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																									m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6))) or
								   --word 3 and word 2 in the center and to handle s in word 1 and word 2															 
								   (m.m_model like concat('%',' ',m_word3,' ',substring(m_word2,1,len(m_word2)-1),' ','%') and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat(m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
									                                                                                            m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1)) or
									                                                                                            m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
									 														                                    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) or
																														        m.m_model like concat('%',' ',m_word6,' ','%') or m.m_model like concat(m_word6,' ','%') or m.m_model like concat('%',' ',m_word6)))) or
																															 										
    				               --word 1 & 6
								   (m.m_model like concat(m_word1,' ',m_word6)  or
								   --to handle s in word 1
									m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word6)  or
								   --word 1 and word 6 in the beginning and handle s in word 2
								   (m.m_model like concat(m_word1,' ',m_word6,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									                                                        m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
															                                m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																							m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																							m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) )) or	
                                    --word 1 and word 6 in the beginning and to handle s in word 1 and word 2
								   (m.m_model like concat(substring(m_word1,1,len(m_word1)-1),' ',m_word6,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									                                                                                    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
									                                                                                    m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																				                                        m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																													    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) )) or	
                                   --word 1 and word 6 at the end and handle s in word 2
								   (m.m_model like concat('%',' ',m_word1,' ',m_word6) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
															                                m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
															                                m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
																							m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																							m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') )) or
                                   --word 1 and word 6 at the end and handle s in word 2 and word 1
								   (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word6) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
									                                                                                    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
									                                                                                    m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
									 													                                m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																													    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') )) or
                                   --word 1 and word 6 in the center and handle s in word 2
								   (m.m_model like concat('%',' ',m_word1,' ',m_word6,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
								                                                                    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
															                                        m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																									m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																									m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5))) or
								   --word 1 and word 6 in the center and handle s in word 2 and word 1															 
								   (m.m_model like concat('%',' ',substring(m_word1,1,len(m_word1)-1),' ',m_word6,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									                                                                                            m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
									                                                                                            m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																							                                    m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																														        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5)))) or
                                   --word 6 & 1
								   (m.m_model like concat(m_word6,' ',m_word1)  or
								   --to handle s in word 1  (word 6 and  word 1)
									m.m_model like concat(m_word6,' ',substring(m_word1,1,len(m_word1)-1))  or
								   --word 6 and word 1 in the beginning and handle s in word 2
								   (m.m_model like concat(m_word6,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
								                                                            m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
									                                                        m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
									  											            m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																							m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) )) or	
                                   --word 6 and word 1 in the beginning and handle s in word 2
								   (m.m_model like concat(m_word6,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									                                                                                    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
									                                                                                    m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
															    					                                    m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																													    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5) )) or	
                                   --word 6 and word 1 at the end and to handle s in word 2
								   (m.m_model like concat('%',' ',m_word6,' ',m_word1) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
								                                                            m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
															                                m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
																							m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																							m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') )) or
                                   --word 6 and word 1 at the end and to handle s in word 2 and word 1
								   (m.m_model like concat('%',' ',m_word6,' ',substring(m_word1,1,len(m_word1)-1)) and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or
									                                                                                    m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or
									                                                                                    m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or
																						                                m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or
																													    m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') )) or
                                  --word 6 and word 1 in the center and to handle s in word 2
								   (m.m_model like concat('%',' ',m_word6,' ',m_word1,' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									                                                                m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
															                                        m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																									m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																									m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5))) or
						          --word 6 and word 1 in the center and to handle s in word 2 and word 1
								   (m.m_model like concat('%',' ',m_word6,' ',substring(m_word1,1,len(m_word1)-1),' ','%') and (m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat(m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
									                                                                                            m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat(substring(m_word2,1,len(m_word2)-1),' ','%') or m.m_model like concat('%',' ',substring(m_word2,1,len(m_word2)-1)) or
									                                                                                            m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat(m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
									 														                                    m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat(m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																														        m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat(m_word5,' ','%') or m.m_model like concat('%',' ',m_word5)))) or
								   (m.m_model like m_word1) or
								   --to handle s
								   (m.m_model like substring(m_word1,1,len(m_word1)-1))  ))))  	
	                                 						                    								 								                                 			                                     
	     Select @MatchId = Min(m_forId) 
               From #ToGetNoName_2
              Where m_forId > @MatchId
					 
    end-- loop Final

   /*select nl.m_forId,nl.m_for,nl.m_name,nl.m_modelname,nl.m_matchtaken,nl.m_cost
	   from #TheNameList nl
	  order by nl.m_forId,nl.m_for,nl.m_name,nl.m_cost*/

	select count(distinct m_forId) from #TheNameList
	   
	 /*  select  distinct nl.m_forId,nl.m_for,nl.m_name,nl.m_modelname,nl.m_matchtaken,nl.m_cost
	     into #TheFinal
	     from #TheNameList nl 
	    where nl.m_modelname like concat(nl.m_for,'%')
          and nl.m_cost = (select top 1  min(nl1.m_cost)
		                     from #TheNameList nl1
	                        where nl1.m_forId = nl.m_forId
		                    group by nl1.m_forId, nl1.m_for
						    order by nl1.m_forId, nl1.m_for)*/
     
	  --first select all the model names which start the same witht the real model ie; Controller  like Controller; Dual Pump
	  --and insert into the Table #TheFinal with the macthing name and lowest cost
	  select nl.m_forId [m_forId],nl.m_for [m_for],nl.m_name [m_name], min(m_cost) [m_cost]
	    into #TheFinal
        from #TheNameList nl
	   where nl.m_modelname like concat(nl.m_for,'%')
       group by nl.m_forId,nl.m_for,nl.m_name
      having nl.m_name =  (select top 1  m_name
	                         from #TheNameList nl1
                            where nl1.m_modelname like concat(nl1.m_for,' ','%')
		                      and nl1.m_forId  = nl.m_forId
	                        group by m_name
	                        order by min(m_cost), nl1.m_name)
	   order by nl.m_forId

       
	--mark the records inserted into Final as Taken = 'Y' in the Table #TheNameList - for all the macthing m_forId 
	update nl
	   set m_matchtaken ='Y'
	  from #TheNameList nl , #TheFinal fl
	 where nl.m_forId = fl.m_forId

	--the next step is to find the matching model names from the table #TheNameList where m_matchtaken  = 'N' (rest of the models)
	--then insert into the table #TheFinal
		/*insert into #TheFinal(m_forId,m_for,m_name,m_modelname,m_matchtaken,m_cost)
		select distinct nl.m_forId,nl.m_for,nl.m_name,nl.m_modelname,nl.m_matchtaken,nl.m_cost
		  from #TheNameList nl 
	     where nl.m_matchtaken = 'N'
		 --  and nl.m_modelname like concat('%',nl.m_for,'%')
		   and nl.m_cost = (select top 1  min(nl1.m_cost)
		                     from #TheNameList nl1
	                        where nl1.m_forId = nl.m_forId
		                    group by nl1.m_forId, nl1.m_for
						    order by nl1.m_forId, nl1.m_for)*/

         insert into #TheFinal(m_forId,m_for,m_name,m_cost)	          
	     select nl.m_forId [m_forId],nl.m_for [m_for],nl.m_name [m_name] , min(m_cost) [m_cost]
	       from #TheNameList nl
	      where nl.m_matchtaken = 'N'
          group by nl.m_forId,nl.m_for,nl.m_name
         having nl.m_name =  (select top 1  m_name
	                            from #TheNameList nl1
                            -- where nl.m_matchtaken = 'N'
	                         --  and nl1.m_forId  = nl.m_forId
		  	                   where nl1.m_forId  = nl.m_forId
	                           group by m_name
	                           order by min(m_cost), nl1.m_name)
	      order by nl.m_forId
		
	 --update the models in #TheNameList with m_matchTaken =  'Y' for all of them in #TheFinal
	 update nl
	    set m_matchtaken ='Y'
	   from #TheNameList nl , #TheFinal fl
	  where nl.m_matchtaken = 'N'
	    and nl.m_forId = fl.m_forId

	  select m_forId,m_for,m_name,m_cost,m_matchtaken
	    from #TheNameList 
	   order by m_forId

	  select * from #TheFinal
	   order by m_forId, m_for
		            
         --update the first table #ToGetNoName_1 which has data with the matching name from the table #TheFinal
         update nn
	        set nn.Match_Name = f.m_name,
	            nn.m_cost = f.m_cost
	       from #ToGetNoName_1 nn, #TheFinal f
          where nn.m_forId = f.m_forId

         --update the rest of the table #ToGetNoName_1 with null, where there is no matching name
         update #ToGetNoName_1
	        set Match_Name = NULL,
	            m_cost = NULL
          where Match_Name is null

       --get the names from the list where there is no match name found
		 --from those names, get a  match from the Default model data stored
		 --now the script is looking for only name with 2 words, later test and add the commented search below
         select b.m_forId [m_forId],b.m_for [m_for],b.m_word1[m_word1],b.m_word2[m_word2],b.m_word3[m_word3],b.m_word4[m_word4],b.m_word5[m_word5],b.m_word6[m_word6],
		        b.m_lastrec[m_lastrec],b.m_matchtaken[m_matchtaken]
           into #ToGetNomatch
           from #ToGetNoName_1 a, #ToGetNoName_2 b
          where a.m_forId  = b.m_forId
            and a.Match_name is null
          order by a.m_forId    
	    
		select * from  #ToGetNomatch
	    --to fetch each record and find the matching model from the table #ToGetNoName_2
        Select @MatchId2 = Min(m_forId) 
         From #ToGetNomatch
 
		--Loop Final2
        While @MatchId2 is not null begin
		      insert into #TheNameList2(m_forId, m_for,m_fromId, m_from,m_short,m_type,m_modelname,m_matchtaken,m_cost,m_name,m_word1,m_word2,m_word3,m_word4,m_word5,m_word6,m_lastrec)
	               select nn.m_forId,nn.m_for,m.id ,m.name,m.shortname,m.Type,m.m_model,@MatchTaken,m.ReplacementCost,coalesce(m.name,null),coalesce(nn.m_word1,null),coalesce(nn.m_word2,null),
				          coalesce(nn.m_word3,null),coalesce(nn.m_word4,null),coalesce(nn.m_word5,null),coalesce(nn.m_word6,null),coalesce(nn.m_lastrec,null)
                     from #ToGetDefaultModels m, #ToGetNomatch nn
                    where nn.m_forId = @MatchId2  
					 --for names with only one word, if it has no space inbetween like to get a match for Rangehood(Client) = Range Hood (AF Model)
					 and ((nn.m_lastrec = 1 and (replace(SUBSTRING(m.m_model,1,LEN(m_word1) +1),' ','') like m_word1))) or 
					     ((nn.m_lastrec = 2 and (m.m_model like concat(m_word1,' ','%')  )))
						 --the code below has to be rewritten and tested across all the 8 data sets (to get > 50%)
					     --for names with two words,check for a match between the first word or second word of the name and the default model
						 --also check for names no space inbetween like to get a match for Rangehood(Client) = Range Hood (AF Model)
					/*     ((nn.m_lastrec = 2 and (m.m_model like concat(m_word1,' ','%') or 
						                         m.m_model like concat(m_word2,' ','%') or
						                         replace(SUBSTRING(m.m_model,1,LEN(m_word1) +1),' ','') like m_word1 or
												 replace(SUBSTRING(m.m_model,1,LEN(m_word2) +1),' ','') like m_word2)))

					  --will recode and test the below for more result, more than 50%
					   and ((nn.m_lastrec = 2 and (m.m_model like concat(m_word1,' ','%')  )))or
					      --((nn.m_lastrec = 2 and (m.m_model like concat(m_word1,' ','%')  or m.m_model like concat(m_word2,' ','%'))))or
					      -- (nn.m_lastrec = 3 and (m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word3,' ','%'))) 
						   (nn.m_lastrec = 3 and (m.m_model like concat(m_word1,' ','%') and ((m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or 
						                                                                       m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3))or (m.m_model like concat(m_word1,' ','%')))) ) or
  					       (nn.m_lastrec = 4 and (m.m_model like concat(m_word1,' ','%') and ((m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or 
						                                                                       m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																							   m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4))or (m.m_model like concat(m_word1,' ','%')))) ) or
 					       (nn.m_lastrec = 5 and (m.m_model like concat(m_word1,' ','%') and ((m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or 
						                                                                       m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or
																							   m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																							   m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4)) or (m.m_model like concat(m_word1,' ','%')))) ) or
					       (nn.m_lastrec = 6 and (m.m_model like concat(m_word1,' ','%') and ((m.m_model like concat('%',' ',m_word1,' ','%') or m.m_model like concat('%',' ',m_word1) or
						                                                                       m.m_model like concat('%',' ',m_word2,' ','%') or m.m_model like concat('%',' ',m_word2) or 
						                                                                       m.m_model like concat('%',' ',m_word3,' ','%') or m.m_model like concat('%',' ',m_word3) or
																							   m.m_model like concat('%',' ',m_word4,' ','%') or m.m_model like concat('%',' ',m_word4) or
																							   m.m_model like concat('%',' ',m_word5,' ','%') or m.m_model like concat('%',' ',m_word5)) or (m.m_model like concat(m_word1,' ','%')))) )*/					 
		 Select @MatchId2 = Min(m_forId) 
               From #ToGetNomatch
              Where m_forId > @MatchId2
					 
         end-- loop Final2

         --Namelist2 
		 select count(distinct m_forId) from #TheNameList2
		 --first select all the model names which start the same witht the real model ie; Controller  like Controller; Dual Pump
	     --and insert into the Table #TheFinal with the macthing name and lowest cost
	     select nl.m_forId [m_forId],nl.m_for [m_for],nl.m_name [m_name], min(m_cost) [m_cost]
	       into #TheFinal2
           from #TheNameList2 nl
	      where nl.m_modelname like concat(nl.m_for,'%')
          group by nl.m_forId,nl.m_for,nl.m_name
         having nl.m_name =  (select top 1  m_name
	                            from #TheNameList2 nl1
                               where nl1.m_modelname like concat(nl1.m_for,' ','%')
		                         and nl1.m_forId  = nl.m_forId
	                           group by m_name
	                           order by min(m_cost), nl1.m_name)
	      order by nl.m_forId
		  --mark the records inserted into Final as Taken = 'Y' in the Table #TheNameList - for all the macthing m_forId 
	      update nl
	         set m_matchtaken ='Y'
	        from #TheNameList2 nl , #TheFinal2 fl
	       where nl.m_forId = fl.m_forId


	 --   select * from #TheNameList2
       insert into #TheFinal2(m_forId,m_for,m_name,m_cost)	          
	     select nl.m_forId [m_forId],nl.m_for [m_for],nl.m_name [m_name] , min(m_cost) [m_cost]
	       from #TheNameList2 nl
	      where nl.m_matchtaken = 'N'
          group by nl.m_forId,nl.m_for,nl.m_name
         having nl.m_name =  (select top 1  m_name
	                            from #TheNameList2 nl1
                            -- where nl.m_matchtaken = 'N'
	                         --  and nl1.m_forId  = nl.m_forId
		  	                   where nl1.m_forId  = nl.m_forId
	                           group by m_name
	                           order by min(m_cost), nl1.m_name)
	      order by nl.m_forId

	
	     --update the models in #TheNameList2 with m_matchTaken =  'Y' for all of them in #TheFinal2
	     update nl
	        set m_matchtaken ='Y'
	       from #TheNameList2 nl , #TheFinal2 fl
	      where nl.m_matchtaken = 'N'
	        and nl.m_forId = fl.m_forId

	    select m_forId,m_for,m_name,m_cost,m_matchtaken
	      from #TheNameList2
	     order by m_forId

	    select * from #TheFinal2
	     order by m_forId, m_for

	    --update the first table #ToGetNoName_1 which has data with the matching name from the table #TheFinal2
         update nn
	        set nn.Match_Name = f.m_name,
	            nn.m_cost = f.m_cost
	       from #ToGetNoName_1 nn, #TheFinal2 f
          where nn.m_forId = f.m_forId

         --update the rest of the table #ToGetNoName_1 with null, where there is no matching name
         update #ToGetNoName_1
	        set Match_Name = NULL,
	            m_cost = NULL
          where Match_Name is null


        --to display the final results
        -- all the model with either matching names or Null value
		--to add next - aug 30, 2021
		--need to include the Matching Model Id here
        select m_forId [SNo], m_for [Model Name], Match_Name,m_cost
          from #ToGetNoName_1 
         order by m_forId
       
       select count(*) from #ToGetNoName_1
        where Match_Name is not null
		 
       --Aug 30, 2021
	   -- the above results only show matching model name, this below statement will show matching Model ids or NULL
	   --will use this till the above statement is modified to include the Model Id
       SELECT g.m_forId[Serial No.], g.m_name [For Model Name] , g.[Match_Name][Matching Model] ,m.id[From Model]
       FROM #ToGetNoName_1 g
       LEFT OUTER JOIN  sel.models m ON g.[Match_Name] = m.[name]
       and  m.[Status] = 'A'
       order by  g.m_forId

end--main

	
