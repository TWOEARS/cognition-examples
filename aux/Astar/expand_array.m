function exp_array=expand_array(node_x,node_y,hn,xTarget,yTarget,CLOSED,MAX_X,MAX_Y,startAngle,targetAngle,xStartPos,yStartPos,xTargetPos,yTargetPos,centroids)
    %Function to return an expanded array
    %This function takes a node and returns the expanded list
    %of successors,with the calculated fn values.
    %The criteria being none of the successors are on the CLOSED list.
    %
    %   Copyright 2009-2010 The MathWorks, Inc.
    
    exp_array=[];
    exp_count=1;
    c2=size(CLOSED,1);%Number of elements in CLOSED including the zeros
    for k= 1:-1:-1
        for j= 1:-1:-1
            if (k~=j || k~=0)  %The node itself is not its successor
                s_x = node_x+k;
                s_y = node_y+j;
                if( (s_x >0 && s_x <=MAX_X) && (s_y >0 && s_y <=MAX_Y))%node within array bound
                    flag=1;                    
                    for c1=1:c2
                        if(s_x == CLOSED(c1,1) && s_y == CLOSED(c1,2))
                            flag=0;
                        end;
                    end;%End of for loop to check if a successor is on closed list.
                    if (flag == 1)
                        
                        %ind=s_x+(s_y-1)*32;
                        centerX=centroids{s_x,s_y}{1,1};
                        centerY=centroids{s_x,s_y}{1,2};
                        dNG=distance(xTargetPos,yTargetPos,centerX,centerY);
                        vNG=[xTargetPos-centerX;yTargetPos-centerY];
                        vNG=vNG/norm(vNG);
                        vTarget=[cos(targetAngle/180*pi);sin(targetAngle/180*pi)];
                        spT=dot(vNG,vTarget);
                        wT=exp(-(spT-1))^3-1;
                        wT=wT*exp(-dNG);

                        
                        
                        
                        dNS=distance(xStartPos,yStartPos,centerX,centerY);
                        vSN=[centerX-xStartPos;centerY-yStartPos];
                        vSN=vSN/norm(vSN);
                        vStart=[cos(startAngle/180*pi);sin(startAngle/180*pi)];
                        spS=dot(vSN,vStart);
                        wS=exp(-(spS-1))^3-1;
                        wS=wS*exp(-dNS);

                        wS=0;
                        wT=0;
                        
                        exp_array(exp_count,1) = s_x;
                        exp_array(exp_count,2) = s_y;
                        exp_array(exp_count,3) = hn+distance(node_x,node_y,s_x,s_y)+wS+wT;%cost of travelling to node
                        exp_array(exp_count,4) = distance(xTarget,yTarget,s_x,s_y);%distance between node and goal
                        exp_array(exp_count,5) = exp_array(exp_count,3)+exp_array(exp_count,4);%fn
                        exp_count=exp_count+1;
                    end%Populate the exp_array list!!!
                end% End of node within array bound
            end%End of if node is not its own successor loop
        end%End of j for loop
    end%End of k for loop    