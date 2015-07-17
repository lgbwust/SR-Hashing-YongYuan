function [ evaluation_info ] = eva_lookup( Rank, trueRank, Vr)

 %Radius=0:4;
Radius=2; %�����뾶
[ntest, ntraining] = size(Rank);
HammIdx=single(zeros(ntest,length(Radius)));
for n=1:ntest
    for h=Radius
%         idx=find(Vr(n,:)<h+1,1,'last');    %�������һ��С��h+1���������� Դ����
        idx=find(Vr(n,:)<h,1,'last');    %�������һ��С��h+1����������
        if(isempty(idx))
            if(h==0)
                idx=0;
            else
                idx=HammIdx(n,h-1);     %ԭ����
 %               idx=HammIdx(n,h-1);  %Radius=2
 %               idx=HammIdx(n,h-3);  %Radius=4
            end
        end
             HammIdx(n,h-1)=idx;   %Radius=1
%         HammIdx(n,h+1)=idx;   %ԭ����
%         HammIdx(n,h-1)=idx;    %Radius=2
%         HammIdx(n,h-3)=idx;    %Radius=4
    end
end

% trueRank = KNN_info.knn_p2;       
M_set=mean(HammIdx);

for n = 1:ntest  
    Rank(n,:) = ismember(Rank(n,:), trueRank(n,:));   %�ж�Rank�Ƿ�ΪtrueRank���Ӽ�
end

Ntotal=size(trueRank,2);
for i=1:length(M_set)
    Pi=0;
    Ri=0;
    for n=1:ntest
        Nreturn=HammIdx(n,i);
        Ntrue=sum(Rank(n,1:Nreturn),2);
        if(Nreturn~=0)
            Pi=Pi+Ntrue/Nreturn;
        end
            Ri=Ri+Ntrue/Ntotal;
    end
    P(i)=Pi/ntest; %�����в��������ļ���׼ȷ���ܺ���ƽ��
    R(i)=Ri/ntest;
end

evaluation_info.recall=R;
evaluation_info.precision=P;
evaluation_info.M_set=M_set;
