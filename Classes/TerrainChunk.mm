//
//  TerrainChunk.m
//  prototype
//
//  Created by Ari Ronen on 10/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TerrainChunk.h"

#import "Liquids.h"
#import "Terrain.h"
#import "Geometry.h"



extern Vector colorTable[256];
static int v_idx=0;

static int v_idx2=0;
static Terrain* ter;

extern unsigned short allIndices[INDICES_MAX];

extern GLshort cubeTexture[];
extern GLshort liquidTexture[2*6*6];
extern GLshort side2ShortVertices[3*6*6];
extern GLshort side3ShortVertices[3*6*6];
extern GLshort side4ShortVertices[3*6*6];
extern GLshort side2Texture[2*6*6];
extern GLshort side3Texture[2*6*6];
extern GLshort side4Texture[2*6*6];
extern GLshort side1Texture[2*6*6];
extern GLshort side1ShortVertices[3*6*6];
extern GLshort ramp1ShortVertices[3*6*6];
extern GLshort ramp2ShortVertices[3*6*6];
extern GLshort ramp3ShortVertices[3*6*6];
extern GLshort ramp4ShortVertices[3*6*6];
extern GLshort ramp2Texture[2*6*6];
extern GLshort ramp3Texture[2*6*6];
extern GLshort ramp4Texture[2*6*6];
extern GLshort ramp1Texture[2*6*6];
extern GLshort cubeShortVertices[3*6*6];
extern GLshort liquidCube[3*6*6];
extern GLubyte cubeColors[3*6];
extern GLfloat zzzzColors[3*6*6];
extern GLfloat cubeNormals[3*6*6];


void TerrainChunk::resetForReuse(){
    
    memset(pblocks,0,sizeof(block8)*CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE);
   // printg("leaking memory freeing small blocks\n");
 //   memset(sblocks,0,sizeof(SmallBlock*)*CHUNK_SIZE3);
    memset(pcolors,0,sizeof(color8)*CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE);
    rtnum_objects=0;
    rtobjects=NULL;
    rtn_vertices=0;
   
    
}
TerrainChunk::TerrainChunk(const int* boundz,Terrain* terrain){
    rebuildCounter=0;
	 
     //   psblocks=sblocks;
		memset(pblocks,0,sizeof(block8)*CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE);
    
  //  pblocks2=blocks2;
    
    rtnum_objects=0;
    rtobjects=NULL;
    objects=NULL;
    needsVBO=FALSE;
    modified=FALSE;
 //   memset(sblocks,0,sizeof(SmallBlock*)*CHUNK_SIZE3);
    
    memset(pcolors,0,sizeof(color8)*CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE);
    indices=NULL;
    rtindices=NULL;
	ter=terrain;
	vertexBuffer=vertexBuffer2=elementBuffer=0;
	
    num_objects=0;
	
	
	for(int i=0;i<6;i++){
		pbounds[i]=boundz[i];
		rbounds[i]=(float)pbounds[i]*BLOCK_SIZE;
		
	}
    /*for(int i=0;i<CHUNK_SIZE3;i++){
        lightsf[i]=randf(.1f)+.9f;
    }*/

    isTesting=0;
	n_vertices=0;
    n_vertices2=0;
    verticesbg=NULL;
    verticesbg2=NULL;
   
        rtobjects=NULL;
        
  //  needsRebuild=FALSE;//just a flag for terrain to use right now, not used internally
    
    
	
}

void TerrainChunk::setBounds( int* boundz){
    modified=FALSE;
	for(int i=0;i<6;i++){
		pbounds[i]=boundz[i];
       
		rbounds[i]=(float)pbounds[i]*BLOCK_SIZE;
	}	
}
static int face_visibility[CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE];
//static Vector lighting[CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE];
static short face_size[CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE*6];

//static vertexStructSmall vertices[CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE*6*6];
//static vertexStructSmall vertices2[CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE*6*6];



//static int count=0;
extern BurnNode* burnList;
static int angledFace[TYPE_ICE_SIDE4-TYPE_STONE_RAMP1+1]={
    5,5,5,5,
    5,5,5,5,
    5,5,5,5,
    5,5,5,5,
   
    
    2,0,3,1,
    2,0,3,1,
    2,0,3,1,
    2,0,3,1,
    
};
#define FACE_FRONT (1<<0)
#define FACE_BACK (1<<1)
#define FACE_LEFT (1<<2)
#define FACE_RIGHT (1<<3)
#define FACE_BOTTOM (1<<4)
#define FACE_TOP (1<<5)
#define FACE_ALL 0b111111
#define RAMP1 0
#define RAMP2 1
#define RAMP3 2
#define RAMP4 3
#define SIDE1 4
#define SIDE2 5
#define SIDE3 6
#define SIDE4 7

//static WetNode* ugly_node;

extern map_t wetmap;
extern bool isRampFaceSolid[4][6];
extern bool isSideFaceSolid[4][6];

//const static int dx[6]={-1,1,0,0,0,0};
//const static int dy[6]={0,0,-1,1,0,0};
//const static int dz[6]={0,0,0,0,-1,1};
const static int dz2[6]={-1,1,0,0,0,0};
const static int dx2[6]={0,0,-1,1,0,0};
const static int dy2[6]={0,0,0,0,-1,1};
extern const GLubyte blockColor[NUM_BLOCKS+1][3];


static bool hasBlocky[CHUNK_SIZE];
static bool hasVisy[CHUNK_SIZE];


extern block8* blockarray;

extern int genLevel(int type,int level);
extern int getLevel(int type);
extern int getBaseType(int type);
extern int g_offcx;
extern int g_offcz;

int TerrainChunk::rebuild2(){   //here be dragons//
    rebuildCounter++;
    
    if(needsVBO){
        printg("not ready to rebuild chunk yet rbc: %d\n",rebuildCounter);
        return -1;
    }
    needsVBO=TRUE;
   
    
   
    
    clearOldVerticesOnly=FALSE;
    has_light=FALSE;
    
   
    v_idx=0;
    v_idx2=0;
    for(int i=0;i<7;i++){
        num_vertices[i]=0;
        num_vertices2[i]=0;
        face_idx[i]=0;
        face_idx2[i]=0;
    }
   
    
   // self.rtnum_objects=self.rtn_vertices=self.rtn_vertices2=0;
	clearMeshes();
    memset(hasBlocky,0,sizeof(bool)*CHUNK_SIZE);
   /* memset(lighting,0,sizeof(Vector)*CHUNK_SIZE);
    for(int y=0;y<CHUNK_SIZE;y++){
        for(int x=0;x<CHUNK_SIZE;x++){
            
			for(int z=0;z<CHUNK_SIZE;z++){
                lighting[(x)*CHUNK_SIZE*CHUNK_SIZE+(z)*CHUNK_SIZE+(y)]=MakeVector(0,0,0);
            }
        }
    }*/
    bool hasSeeThrough=FALSE;
    bool hasAnything=FALSE;
    for(int y=0;y<CHUNK_SIZE;y++){
        for(int x=0;x<CHUNK_SIZE;x++){
			for(int z=0;z<CHUNK_SIZE;z++){
				int type=pblocks[CC(x,z,y)];
                if( type==TYPE_LIGHTBOX){
                    has_light=TRUE;
                    //[self setLand:x:z:y:TYPE_GRASS];
                    //type=TYPE_GRASS;
                }
				if(type<0||type>NUM_BLOCKS){
					setLand(x,z,y,TYPE_STONE);
                    
                    hasAnything=TRUE;
                    hasBlocky[y]=TRUE;
					
				}else if(blockinfo[type]&IS_ATLAS2){
                    hasSeeThrough=TRUE;
                    hasAnything=TRUE;
                    hasBlocky[y]=TRUE;
                }else if(type==TYPE_CUSTOM){
                  /*
                    SmallBlock* sb=sblocks[CC(x,z,y)];
                    if(sb==NULL){
                        sblocks[CC(x,z,y)]=sb=malloc(sizeof(SmallBlock));
                        printg("Custom with no blocks??\n");
                        for(int i=0;i<8;i++){
                            if(arc4random()%2==0)sb->blocks[i]=0;
                            else{
                                
                                sb->blocks[i]=arc4random()%NUM_BLOCKS;
                                if(blockinfo[sb->blocks[i]]&IS_OBJECT)sb->blocks[i]=TYPE_NONE;
                                
                                if(arc4random()%2==0)sb->colors[i]=0;
                                else sb->colors[i]=arc4random()%30;
                                
                            }
                        }
                    }
                  
                    
                    hasSeeThrough=TRUE;
                    hasAnything=TRUE;
                    hasBlocky[y]=TRUE;*/
                }else if(type==TYPE_LIGHTBOX){
                    /*Vector color=colorTable[colors[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y]];
                    if(colors[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y]==0){
                        color=MakeVector(blockColor[type][0]/255.0f,blockColor[type][1]/255.0f,blockColor[type][2]/255.0f);
                    }int r=6;
                    for(int dx=-r;dx<=r;dx++){
                        for(int dz=-r;dz<=r;dz++){
                            for(int dy=-r;dy<=r;dy++){
                                if(dx+x<0||dx+x>=CHUNK_SIZE||dy+y<0||dy+y>=CHUNK_SIZE||dz+z<0||dz+z>=CHUNK_SIZE)continue;
                                int type=blocks[(x+dx)*CHUNK_SIZE*CHUNK_SIZE+(z+dz)*CHUNK_SIZE+(y+dy)];
                                if(type==TYPE_NONE||type==TYPE_LIGHTBOX)continue;
                                int min=MAX(MAX(ABS(dx),ABS(dz)),ABS(dy));
                                if(min<=0||min>r)continue;      
                                float strength=((float)r-(min-1))/(float)r;
                                //  strength*=strength;
                                Vector v=lighting[(x+dx)*CHUNK_SIZE*CHUNK_SIZE+(z+dz)*CHUNK_SIZE+(y+dy)];
                                
                                v.x+=color.x*strength;
                                v.y+=color.y*strength;
                                v.z+=color.z*strength;
                                if(v.x>1)v.x=1;
                                if(v.y>1)v.y=1;
                                if(v.z>1)v.z=1;
                                if(v.x!=0||v.y!=0||v.z!=0){
                                    //  printg("strength: %f\n",strength);
                                }
                                lighting[(x+dx)*CHUNK_SIZE*CHUNK_SIZE+(z+dz)*CHUNK_SIZE+(y+dy)]=v;
                            }
                        }
                    }*/
                    hasBlocky[y]=TRUE;
                    hasAnything=TRUE;
                }else if(type!=0){
                    hasBlocky[y]=TRUE;
                    hasAnything=TRUE;
                    if(type==TYPE_DOOR_TOP||type==TYPE_GOLDEN_CUBE||type==TYPE_FLOWER||type==TYPE_PORTAL_TOP){
                        if(type!=TYPE_DOOR_TOP&&type!=TYPE_GOLDEN_CUBE&&type!=TYPE_PORTAL_TOP){
                            
                          //  printg("flower in chunk, les do it\n"); flowers supported!
                        }
                        num_objects++;
                    }
                }
			}
			
		}
	}
    if(!hasAnything){//printg("return early 1\n");
         //printg("im gonna clear some old vertices\n");
        clearOldVerticesOnly=TRUE;
        
        return 0;}
    hasAnything=FALSE;
    memset(face_visibility,0,sizeof(int)*CHUNK_SIZE*CHUNK_SIZE*CHUNK_SIZE);
    memset(hasVisy,0,sizeof(bool)*CHUNK_SIZE);
    int ex=pbounds[0]+CHUNK_SIZE;
    int ez=pbounds[2]+CHUNK_SIZE;
    int ey=pbounds[1]+CHUNK_SIZE;
    
   
    if(hasSeeThrough){
        for(int gy=pbounds[1];gy<ey;gy++){
            if(!hasBlocky[gy-pbounds[1]])continue;
            for(int gx=pbounds[0];gx<ex;gx++){
                
                for(int gz=pbounds[2];gz<ez;gz++){
                   
                    int idx1= GBLOCKIDX(gx,gz,gy);
                    if(!blockarray[idx1])continue;       
                    if((blockinfo[blockarray[idx1]]&IS_RAMPORSIDE)){
                        hasAnything=TRUE;
                        hasVisy[gy-pbounds[1]]=TRUE;
                        
                        face_visibility[(gx-pbounds[0])*(CHUNK_SIZE*CHUNK_SIZE)+(gz-pbounds[2])*(CHUNK_SIZE)+(gy-pbounds[1])]=FACE_ALL;
                        
                        continue;
                    }
                    
                    int isvisible=0;            
                    for(int f=0;f<6;f++){
                        int type;
                       
                        
                        type=GBLOCK_SAFE(gx+dx2[f],gz+dz2[f],gy+dy2[f]);
                        if((gx==0&&dx2[f]>0)||(gz==0&&dz2[f]>0)||(gy==0&&dy2[f]<0))continue;
                        if(blockinfo[type]&IS_NOTSOLID||(f==5&&blockinfo[blockarray[idx1]]&IS_LIQUID&&getLevel(blockarray[idx1])<4)){
                            isvisible|=1<<f;
                            if(blockinfo[type]&IS_ATLAS2){
                                if(blockinfo[type]&IS_LIQUID){
                                    if(blockinfo[type]==blockinfo[blockarray[idx1]]) 
                                        if((f==4||f==5||getLevel(type)>=getLevel(blockarray[idx1]))&&pcolors[(gx-pbounds[0])*(CHUNK_SIZE*CHUNK_SIZE)+(gz-pbounds[2])*(CHUNK_SIZE)+(gy-pbounds[1])]==getColorc(gx+dx2[f] ,gz+dz2[f] ,gy+dy2[f])){
                                            isvisible&=~(1<<f);
                                        }
                                    
                                }else 
                                    if(type==blockarray[idx1]){
                                        if(pcolors[(gx-pbounds[0])*(CHUNK_SIZE*CHUNK_SIZE)+(gz-pbounds[2])*(CHUNK_SIZE)+(gy-pbounds[1])]==getColorc(gx+dx2[f],gz+dz2[f],gy+dy2[f])){
                                            
                                            
                                            isvisible&=~(1<<f);
                                            
                                        }
                                    }
                            }
                        }
                        
                        
                    }
                    if(isvisible){hasAnything=TRUE;
                        hasVisy[gy-pbounds[1]]=TRUE;
                    }
                    face_visibility[(gx-pbounds[0])*(CHUNK_SIZE*CHUNK_SIZE)+(gz-pbounds[2])*(CHUNK_SIZE)+(gy-pbounds[1])]=isvisible;
                }
            }
        }       
    }else
        for(int gy=pbounds[1];gy<ey;gy++){
            if(!hasBlocky[gy-pbounds[1]])continue;
            for(int gx=pbounds[0];gx<ex;gx++){
                
                for(int gz=pbounds[2];gz<ez;gz++){
                    

                    
                   
                    
                    
                    
                    //if(!gx||!gy||!gz||gx+1==T_HEIGHT||gz+1==T_HEIGHT||gy+1==T_HEIGHT)continue;
                    
                    if(!GBLOCK(gx,gz,gy))continue;
                    int isvisible=0;
                    
                    
                    
                    if((IS_NOTSOLID&blockinfo[GBLOCK(gx,gz,gy+1)]))isvisible|=FACE_TOP;
                    if((IS_NOTSOLID&blockinfo[GBLOCK_SAFE(gx,gz,gy-1)]))isvisible|=FACE_BOTTOM;
                    
                    // crash count 9  are we not bounds checking when we do these border checks??? 
                    if(
                       (IS_NOTSOLID&blockinfo[
                                              GBLOCK(gx+1,gz,gy)
                                              ]
                        ) )isvisible|=FACE_RIGHT;
                    if((IS_NOTSOLID&blockinfo[GBLOCK(gx-1,gz,gy)]))isvisible|=FACE_LEFT;
                    if((IS_NOTSOLID&blockinfo[GBLOCK(gx,gz+1,gy)]))isvisible|=FACE_BACK;
                    if((IS_NOTSOLID&blockinfo[GBLOCK(gx,gz-1,gy)]))isvisible|=FACE_FRONT;
                    
                    if(isvisible){hasAnything=TRUE;
                        hasVisy[gy-pbounds[1]]=TRUE;
                    }
                    face_visibility[(gx-pbounds[0])*(CHUNK_SIZE*CHUNK_SIZE)+(gz-pbounds[2])*(CHUNK_SIZE)+(gy-pbounds[1])]=isvisible;
                }
            }
        }
    
    
    if(pbounds[1]==0){
        for(int x=0;x<CHUNK_SIZE;x++)
            for(int z=0;z<CHUNK_SIZE;z++)
                face_visibility[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+0]&=~FACE_BOTTOM;
    }else if(pbounds[1]+CHUNK_SIZE==T_HEIGHT){
        for(int x=0;x<CHUNK_SIZE;x++)
            for(int z=0;z<CHUNK_SIZE;z++)
                if(pblocks[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+CHUNK_SIZE-1]){
                    face_visibility[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+CHUNK_SIZE-1]|=FACE_TOP;
                    hasAnything=TRUE;
                    hasVisy[CHUNK_SIZE-1]=TRUE;
                }
    }
   
    
    if(!hasAnything){   
       
        
        clearOldVerticesOnly=TRUE;
        return 0;
    }
    
    for(int y=0;y<CHUNK_SIZE;y++){
        if(!hasVisy[y])continue;
        for(int x=0;x<CHUNK_SIZE;x++){		
			for(int z=0;z<CHUNK_SIZE;z++){
                if(!face_visibility[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+y])continue;
                
				int type=pblocks[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y];
                if((blockinfo[type]&IS_OBJECT)||(blockinfo[type]&IS_PORTAL)){
                    for(int f=0;f<6;f++)
                    face_size[x*(CHUNK_SIZE*CHUNK_SIZE*6)+z*(CHUNK_SIZE*6)+y*6+f]=1;
                    continue;
                }
                int isvisible=face_visibility[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+y];
                
                
            //UNCOMMENT FOR FACE MERGING    color8 c1=colors[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+y];
                
                int d;
                
                for(int f=0;f<6;f++){
                    if(isvisible&(1<<f)){                        
                        if(f==5||f==4||f==0||f==1){//top
                            d=1;
                            
                        }else {
                            d=5;
                        }
                        
                        int size=1;/* //UNCOMMENT FOR FACE MERGING
                        if(!(type>=TYPE_STONE_RAMP1&&type<=TYPE_ICE_SIDE4)&&type!=TYPE_CUSTOM&&!(IS_LIQUID&blockinfo[type])&&!(IS_FLAMMABLE&blockinfo[type]&&isOnFire(x+bounds[0],z+bounds[2],y+bounds[1])))
                            while(1){
                                int nx=x+size*dx[d];
                                int ny=y+size*dy[d];
                                int nz=z+size*dz[d];
                                if(nx<0||ny<0||nz<0||nx>=CHUNK_SIZE||ny>=CHUNK_SIZE||nz>=CHUNK_SIZE)break;
                                int ntype=blocks[nx*CHUNK_SIZE*CHUNK_SIZE+nz*CHUNK_SIZE+ny];
                                if(ntype!=type)break;
                                color8 c2=colors[nx*(CHUNK_SIZE*CHUNK_SIZE)+nz*(CHUNK_SIZE)+ny];
                                if(c1!=c2)break;
                                if(!(face_visibility[nx*(CHUNK_SIZE*CHUNK_SIZE)+nz*(CHUNK_SIZE)+ny]&(1<<f))){
                                    break;
                                }
                                if(!
                                   v_equals(lighting[nx*(CHUNK_SIZE*CHUNK_SIZE)+nz*(CHUNK_SIZE)+ny],lighting[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+y]))break;
                                if(f==5&&getShadow(x+bounds[0],z+bounds[2],y+bounds[1])!=getShadow(nx+bounds[0],nz+bounds[2],ny+bounds[1]))break;            
                                
                                face_visibility[nx*(CHUNK_SIZE*CHUNK_SIZE)+nz*(CHUNK_SIZE)+ny]&=~(1<<f);
                                
                                size++;
                                if(size>32)break;
                            }*/
                        face_size[x*(CHUNK_SIZE*CHUNK_SIZE*6)+z*(CHUNK_SIZE*6)+y*6+f]=size;
                    }
                }
				
			}
		}
	}
    int objidx=0;
    if(num_objects>0){
        objects=(StaticObject*)malloc(sizeof(StaticObject)*num_objects);
        
    }
    for(int y=0;y<CHUNK_SIZE;y++){
        if(!hasVisy[y])continue;
        for(int x=0;x<CHUNK_SIZE;x++){
            
			for(int z=0;z<CHUNK_SIZE;z++){
                if(!face_visibility[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+y])continue; 
                
                int type=pblocks[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y];
                int isvisible=face_visibility[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+y];
                if(blockinfo[type]&IS_PORTAL){
                   
                    if(type==TYPE_PORTAL_TOP){
                        
                        objects[objidx].color=pcolors[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y];
                       
                        objects[objidx].open=FALSE;
                        objects[objidx].type=TYPE_PORTAL_TOP;
                        objects[objidx].dir=getLandc(x+pbounds[0],z+pbounds[2],y+pbounds[1]-1)-TYPE_PORTAL1;
                        objects[objidx].pos.x=x+pbounds[0];
                        objects[objidx].pos.y=y-1+pbounds[1];
                        objects[objidx].pos.z=z+pbounds[2];
                        World::getWorld->terrain->portals->addPortal(x+pbounds[0],y+pbounds[1],z+pbounds[2],objects[objidx].dir,  objects[objidx].color);
                        
                        objidx++;
                    }
                    for(int f=0;f<6;f++){	
                        
                        if( isvisible&(1<<f) ){
                            n_vertices+=6;
                            
                            num_vertices[f]+=6;
                        }
                    }
                    
                    
                }else if(blockinfo[type]&IS_OBJECT){
                        //printg("object type detected\n");

                        face_visibility[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+y]=0;
                        if(type==TYPE_DOOR_TOP){
                            
                            objects[objidx].color=pcolors[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y];
                            objects[objidx].open=FALSE;
                            objects[objidx].type=TYPE_DOOR_TOP;
                            objects[objidx].dir=getLandc(x+pbounds[0],z+pbounds[2],y+pbounds[1]-1)-TYPE_DOOR1;
                            objects[objidx].dir=ABS(objects[objidx].dir)%4;
                            objects[objidx].rot=M_PI/2;
                            objects[objidx].ani=0;
                            objects[objidx].pos.x=x+pbounds[0];
                            objects[objidx].pos.y=y-1+pbounds[1];
                            objects[objidx].pos.z=z+pbounds[2];
                            
                          // printg("door[%d] %f, %f, %f \n", objidx, objects[objidx].pos.x,  objects[objidx].pos.y,  objects[objidx].pos.z);

                            
                            objidx++;
                        }else if(type==TYPE_GOLDEN_CUBE){
                            // printg("got cube\n");
                            objects[objidx].color=pcolors[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y];
                            objects[objidx].open=FALSE;
                            objects[objidx].type=TYPE_GOLDEN_CUBE;
                            objects[objidx].dir=0;
                            objects[objidx].pos.x=x+pbounds[0];
                            objects[objidx].pos.y=y+pbounds[1];
                            objects[objidx].pos.z=z+pbounds[2];
                            
                            objidx++;
                        }else if(type==TYPE_FLOWER){
                            // printg("got flower\n");
                            objects[objidx].color=pcolors[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y];
                            objects[objidx].open=FALSE;
                            objects[objidx].type=TYPE_FLOWER;
                            objects[objidx].dir=0;
                            objects[objidx].pos.x=x+pbounds[0];
                            objects[objidx].pos.y=y+pbounds[1];
                            objects[objidx].pos.z=z+pbounds[2];
                            
                            objidx++;
                            
                        }
                    }else
                        if(blockinfo[type]&IS_ATLAS2){
                            for(int f=0;f<6;f++){		
                                if( isvisible&(1<<f) ){
                                    n_vertices2+=6;                          
                                    num_vertices2[f]+=6;
                                }
                            }
                            
                            
                        } else if(type==TYPE_CUSTOM)       {
                            //printg("bad count3\n");
                            /*
                            face_visibility[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+y]=FACE_ALL;
                            SmallBlock* sb=sblocks[ x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y];
                            for(int i=0;i<8;i++){
                                int type2=sb->blocks[i];  
                                
                                if(type2<=0||(blockinfo[type2]&IS_OBJECT))continue;
                                if(blockinfo[type2]&IS_ATLAS2){
                                    for(int f=0;f<6;f++){		
                                        
                                        n_vertices2+=6;                          
                                        num_vertices2[f]+=6;
                                        
                                    }
                                    
                                    
                                }else{
                                    for(int f=0;f<6;f++){	
                                        
                                        
                                        n_vertices+=6;
                                        if(type2>=TYPE_STONE_RAMP1&&type2<=TYPE_ICE_SIDE4&&f==angledFace[type2-TYPE_STONE_RAMP1])
                                            num_vertices[6]+=6;                
                                        else
                                            num_vertices[f]+=6;
                                        
                                    }
                                }
                            }*/
                        }else{
                            if(type>=TYPE_STONE_RAMP1&&type<=TYPE_ICE_SIDE4){
                                isvisible|=(1<<angledFace[type-TYPE_STONE_RAMP1]);
                                face_visibility[x*(CHUNK_SIZE*CHUNK_SIZE)+z*(CHUNK_SIZE)+y]=isvisible;
                            }
                            for(int f=0;f<6;f++){	
                                
                                if( isvisible&(1<<f) ){
                                    n_vertices+=6;
                                    if(type>=TYPE_STONE_RAMP1&&type<=TYPE_ICE_SIDE4&&f==angledFace[type-TYPE_STONE_RAMP1])
                                        num_vertices[6]+=6;                
                                    else
                                        num_vertices[f]+=6;
                                }
                            }
                            
                            
                            
                        }
            }
		}
	}
    verticesbg=(vertexStructSmall*)malloc(sizeof(vertexStructSmall)*n_vertices);
    verticesbg2=(vertexStructSmall*)malloc(sizeof(vertexStructSmall)*n_vertices2);
    if(objidx<num_objects){num_objects=objidx;
    
        printg("objidx<num_objects?\n");
    }else if(objidx!=num_objects){
        printg("miscount on num objects\n");
    }
    if(num_objects>0){
        //printg("%d doors in this chunk \n",num_objects);
    }
    if(!n_vertices&&!n_vertices2){//printg("return early 3\n");
     //    printg("im gonna clear some old vertices\n");
        clearOldVerticesOnly=TRUE;
        
        return 0;}
    //face_idx[0]=0;
    //face_idx2[0]=0;
    for(int i=1;i<7;i++){       
        face_idx[i]=num_vertices[i-1]+face_idx[i-1];
        face_idx2[i]=num_vertices2[i-1]+face_idx2[i-1];
        if(face_idx[i]>n_vertices){
            printg("f1  %d>%d\n",face_idx[i],n_vertices);
            
        }
        if(face_idx2[i]>n_vertices2){
            printg("f2  %d>%d\n",face_idx2[i],n_vertices2);
            
        }
    }
    
    float skylight=1.0f;
    float light[3]={1.0f,1.0f,1.0f};
    if(!LOW_MEM_DEVICE&&v_equals(World::getWorld->terrain->final_skycolor,colorTable[54]))
        skylight=.35f;
    
    Resources* res=Resources::getResources;
	for(int idx=0;idx<CHUNK_SIZE3;idx++){
        if(!face_visibility[idx])continue;
        
        int isvisible=face_visibility[idx];        
        int type=pblocks[idx];
        int y=idx%CHUNK_SIZE;
        int z=(idx/CHUNK_SIZE)%CHUNK_SIZE;
        int x=(idx/CHUNK_SIZE2)%CHUNK_SIZE;        
        
        BOOL burned=FALSE;
        if(IS_FLAMMABLE&blockinfo[type]&&isOnFire(x+pbounds[0],z+pbounds[2],y+pbounds[1])){
            burned=TRUE;
            
        }
        
        
        short offsets[3];
        offsets[0]=x;
        offsets[1]=y;
        offsets[2]=z;	
        
       /* if(type==TYPE_CUSTOM){
            //custom start
            SmallBlock* sb=sblocks[idx];
            for(int ci=0;ci<8;ci++){
                if(sb->blocks[ci]!=0){
                    int offsets2[3];
                    if(ci%2==0)offsets2[1]=2;
                    else offsets2[1]=0;
                    
                    if((ci/2)%2==0)offsets2[2]=2;
                    else offsets2[2]=0;
                    
                    if((ci/4)%2==0)offsets2[0]=2;
                    else offsets2[0]=0;
                    
                    float paint[3];
                    float light[3];
                    int type=sb->blocks[ci];
                    if(type==0)continue;
                    color8 clr=sb->colors[ci];                    
                    BOOL coloring=false;
                    BOOL isLiquid=false;
                    Vector cl=colorTable[clr];
                    paint[0]=cl.x;
                    paint[1]=cl.y;
                    paint[2]=cl.z;
                   // Vector lightv=lighting[(x)*CHUNK_SIZE*CHUNK_SIZE+(z)*CHUNK_SIZE+(y)];
                   // light[0]=lightv.x;
                   // light[1]=lightv.y;
                   // light[2]=lightv.z;
                    //if(light[0]!=0||light[1]!=0||light[2]!=0)
                    // printg("lighting at(%d,%d,%d),  (%f,%f,%f)\n",x,y,z,light[0],light[1],light[2]);
                    //int corners[4]={4,4,4,4};
                    int top_shadow=255;
                    if(FACE_TOP&isvisible){
                        top_shadow-=0;//getShadow(x+bounds[0],z+bounds[2],y+bounds[1]);
                    }
                    // if(top_shadow!=255)NSLog(@"yay");
                    vertexStructSmall* vert_array=verticesbg;
                    int vert_c=v_idx;
                    //NSLog(@"v_idx: %d, nvert:%d",v_idx,n_vertices);
                    BOOL is2=FALSE;
                    if(blockinfo[type]&IS_ATLAS2){
                        is2=TRUE;
                        vert_array=verticesbg2;
                        vert_c=v_idx2;
                    }
                    
                    int rtype;
                    int sideface=-1;
                    int wshadow=80;
                    
                    int specialFace=-1;
                    
                    int gshadows[8]={235,178,191,223,  204, 159,127, 160,  };
                    if((type>=TYPE_STONE_RAMP1&&type<=TYPE_ICE_SIDE4)){
                        specialFace=angledFace[type-TYPE_STONE_RAMP1];
                        rtype=type%4;
                        if(type>=TYPE_STONE_SIDE1)rtype+=4;
                        wshadow=gshadows[rtype];
                        sideface=specialFace;
                        
                        
                        //corners[0]=corners[1]=corners[2]=corners[3]=0;
                        if((type>=TYPE_STONE_RAMP1&&type<=TYPE_ICE_RAMP4))
                            top_shadow=( wshadow )/255.0f*top_shadow;
                    }
                    
                    if(clr==0){
                        if(type==TYPE_GRASS||type==TYPE_GRASS2||type==TYPE_GRASS3||type==TYPE_TNT||type==TYPE_FIREWORK||type==TYPE_BRICK||type==TYPE_VINE||type==TYPE_TRAMPOLINE){
                            coloring=TRUE;
                        }
                        for(int i=0;i<3;i++)
                            paint[i]=(float)blockColor[type][i]/255;
                    }
                    const GLshort* cubeVertices=cubeShortVertices;
                    const GLshort* cubeTextureCustom=cubeTexture;
                    if(blockinfo[type]&IS_LIQUID){
                        isLiquid=TRUE;
                        int level=getLevel(type);
                        int maxlevel=0;
                        int maxleveld=0;
                        for(int f=0;f<6;f++){
                            if(!( isvisible&(1<<f) ) ){
                                if(f!=4&&f!=5){
                                    int type2=getLandc((bounds[0]+x+dx2[f]),(bounds[2]+z+dz2[f]),(bounds[1]+y+dy2[f]));
                                    int level2=getLevel(type2);
                                    if(level2>maxlevel){
                                        maxlevel=level2;
                                        maxleveld=f;
                                    }
                                }
                                continue;
                            }
                            int sf=f*6*3;
                            if(f!=4&&f!=5){
                                int type2=getLandc(bounds[0]+x+dx2[f],(bounds[2]+z+dz2[f]),(bounds[1]+y+dy2[f]));
                                int level2=getLevel(type2);
                                if(level2<level){
                                    if(getBaseType(type2)==getBaseType(type)){
                                        
                                        if(level2>maxlevel){
                                            maxlevel=level2;
                                            maxleveld=f;
                                        }
                                    }
                                }else level2=level;
                                
                                
                                
                                for(int v=0;v<6;v++){
                                    int sv=sf+v*3;
                                    
                                    
                                    
                                    if(cubeShortVertices[sv+1]){
                                        liquidCube[sv+1]=level;
                                    }else{
                                        liquidCube[sv+1]=level2;
                                    }
                                    
                                    
                                }
                                
                            }else{
                                for(int v=0;v<6;v++){
                                    int sv=sf+v*3;
                                    
                                    
                                    
                                    if(cubeShortVertices[sv+1]){
                                        liquidCube[sv+1]=level;
                                    }
                                    
                                    
                                }  
                            }
                            
                        }
                        
                        if(maxlevel==level)maxleveld=0;
                        if(maxlevel<level)maxleveld=(2+maxleveld)%4;
                        const GLshort* cubeVerticesTop;
                        //  printg("maxleveld:%d",maxleveld);
                        if(maxleveld==0){                
                            cubeVerticesTop=side3Texture;
                        }else if(maxleveld==1){               
                            cubeVerticesTop=side1Texture;
                        }else if(maxleveld==2){               
                            cubeVerticesTop=side2Texture;
                        }else if(maxleveld==3){               
                            cubeVerticesTop=side4Texture;
                        }
                        
                        for(int v=0;v<6;v++){
                            for(int coord=0;coord<2;coord++){
                                
                                liquidTexture[5*6*2+v*2+coord]=cubeVerticesTop[5*6*2+v*2+coord];
                                
                            }
                        }
                        
                        cubeTextureCustom=liquidTexture;
                        
                        
                    }else 
                        if(type>=TYPE_STONE_SIDE1&&type<=TYPE_ICE_SIDE4){
                            
                            if(type%4==0){
                                cubeVertices=side1ShortVertices;
                                cubeTextureCustom=side1Texture;
                            }else if((type+1)%4==0){
                                cubeVertices=side2ShortVertices;
                                cubeTextureCustom=side2Texture;
                            }else if((type+2)%4==0){
                                cubeVertices=side3ShortVertices;
                                cubeTextureCustom=side3Texture;
                            }else if((type+3)%4==0){
                                cubeVertices=side4ShortVertices;
                                cubeTextureCustom=side4Texture;
                            }
                            
                        }else if(type>=TYPE_STONE_RAMP1&&type<=TYPE_ICE_RAMP4){
                            if(type%4==0){
                                cubeVertices=ramp1ShortVertices;
                                cubeTextureCustom=ramp1Texture;
                            }else if((type+1)%4==0){
                                cubeVertices=ramp2ShortVertices;
                                cubeTextureCustom=ramp2Texture;
                            }else if((type+2)%4==0){
                                cubeVertices=ramp3ShortVertices;
                                cubeTextureCustom=ramp3Texture;
                            }else if((type+3)%4==0){
                                cubeVertices=ramp4ShortVertices;
                                cubeTextureCustom=ramp4Texture;
                            }
                            
                        }
                    
                    for(int f=0;f<6;f++){
                        if(!( isvisible&(1<<f) ) )continue;
                        int size=face_size[x*(CHUNK_SIZE*CHUNK_SIZE*6)+z*(CHUNK_SIZE*6)+y*6+f];
                        int mergeAxis;
                        if(f==5||f==4||f==0||f==1){
                            mergeAxis=0;
                        }else{
                            mergeAxis=2;
                        }
                        
                        
                        if(!is2){
                            if(f==specialFace){
                                vert_c=face_idx[6];
                                face_idx[6]+=6;
                            }else{
                                vert_c=face_idx[f];
                                face_idx[f]+=6;  
                            }
                        }else{
                            vert_c=face_idx2[f];
                            face_idx2[f]+=6;  
                            
                        }
                        
                        int sf=f*6*3;
                        
                        int bf=blockTypeFaces[type][f];
                        if(coloring){
                            for(int i=0;i<3;i++)
                                paint[i]=1.0f;
                            
                            if(bf==TEX_GRASS_TOP||bf==TEX_GRASS_TOP2)
                            {
                                
                                
                                for(int i=0;i<3;i++){
                                    paint[i]=(float)(blockColor[type][i])/255;
                                    if(paint[i]<0)paint[i]=0;
                                }
                            }
                            else if(bf==TEX_GRASS_SIDE)
                                bf=TEX_GRASS_SIDE_COLOR;
                            else if(bf==TEX_TNT_SIDE)
                                bf=TEX_TNT_SIDE_COLOR;
                            else if(bf==TEX_TNT_TOP)
                                bf=TEX_TNT_TOP_COLOR;
                            else if(bf==TEX_BRICK)
                                bf=TEX_BRICK_COLOR;
                            else if(bf==TEX_DIRT){
                                for(int i=0;i<3;i++)
                                    paint[i]=(float)blockColor[TEX_DIRT][i]/255;
                            }else if(!(blockinfo[type]&IS_LIQUID)&&type!=TYPE_VINE){
                                for(int i=0;i<3;i++)
                                    paint[i]=(float)blockColor[type][i]/255;
                            }
                            
                        }
                        if(type!=TYPE_LIGHTBOX)
                            for(int i=0;i<3;i++){
                                
                                float n=light[i]+paint[i]*4.0f/5.0f;
                                if(n<=paint[i])paint[i]=n;
                                
                            }
                        CGPoint tp;
                        tp=[res getBlockTexShort:bf];
                        
                        
                        
                        for(int v=0;v<6;v++){
                            int sv=sf+v*3;
                            for(int coord=0;coord<3;coord++){
                                
                                
                                if(isLiquid){
                                    vert_array[vert_c].position[coord]=liquidCube[sv+coord]/2+4*offsets[coord]+offsets2[coord];
                                    
                                }else if(coord==mergeAxis){
                                    
                                    vert_array[vert_c].position[coord]=2*cubeVertices[sv+coord]*size+4*offsets[coord]+offsets2[coord];
                                    
                                }
                                else{
                                    vert_array[vert_c].position[coord]=2*cubeVertices[sv+coord]+4*offsets[coord]+offsets2[coord];                    
                                }
                                int color;
                                if(type==TYPE_CLOUD&&f==4)
                                    color=paint[coord]*180;
                                else if(f==5){                      
                                    color=paint[coord]*top_shadow;
                                }else if(type>=TYPE_STONE_SIDE1&&type<=TYPE_ICE_SIDE4&&sideface==f){
                                    color=paint[coord]*wshadow;
                                }
                                else
                                    color=paint[coord]*(float)cubeColors[f*3+coord];
                                
                                if(burned){
                                    color/=2.0f;
                                }
                                if( color>255) vert_array[vert_c].colors[coord]=255;
                                else vert_array[vert_c].colors[coord]=color;
                            }
                            
                            int st=f*6*2+v*2;
                            
                            vert_array[vert_c].texs[0]=cubeTextureCustom[st]*size;
                            
                            
                            
                            
                            
                            vert_array[vert_c].texs[1]=cubeTextureCustom[st+1]*tp.y+tp.x;
                            if(!(blockinfo[type]&IS_ATLAS2)){
                                v_idx++;
                                 
                                vert_array[vert_c].colors[3]=0;
                            }
                            else{
                                v_idx2++;
                                if(blockinfo[type]&IS_WATER)vert_array[vert_c].colors[3]=145;
                                else
                                    vert_array[vert_c].colors[3]=255;
                            }
                            vert_c++;
                        }
                    }
                    
                    
                }
            }
            //custom end
            continue;
             
        }*/
        float paint[3];
        
        color8 clr=pcolors[idx];
        if(blockinfo[type]&IS_PORTAL){
            clr=0;
          
        }
        BOOL coloring=false;
        BOOL isLiquid=false;
        Vector cl=colorTable[clr];
        paint[0]=cl.x;
        paint[1]=cl.y;
        paint[2]=cl.z;
       
       
        //float shadow=0.5f;//getShadow(x+bounds[0],z+bounds[2],y+bounds[1]);
        if(skylight!=1.0f){
        light[0]=calcLight(x+pbounds[0],z+pbounds[2],y+pbounds[1],skylight,0);
        light[1]=calcLight(x+pbounds[0],z+pbounds[2],y+pbounds[1],skylight,1);
        light[2]=calcLight(x+pbounds[0],z+pbounds[2],y+pbounds[1],skylight,2);
        }
        /*lightsf[CC(x,z,y)]+*/
    //    Vector lightv=lighting[(x)*CHUNK_SIZE*CHUNK_SIZE+(z)*CHUNK_SIZE+(y)];
    //    light[0]=lightv.x;
    //    light[1]=lightv.y;
    //    light[2]=lightv.z;
        //if(light[0]!=0||light[1]!=0||light[2]!=0)
        // printg("lighting at(%d,%d,%d),  (%f,%f,%f)\n",x,y,z,light[0],light[1],light[2]);
        //int corners[4]={4,4,4,4};
        int top_shadow=255;
        if(FACE_TOP&isvisible){
            top_shadow-=0;//getShadow(x+bounds[0],z+bounds[2],y+bounds[1]);
        }
        // if(top_shadow!=255)NSLog(@"yay");
        vertexStructSmall* vert_array=verticesbg;
        int vert_c=v_idx;
        //NSLog(@"v_idx: %d, nvert:%d",v_idx,n_vertices);
        BOOL is2=FALSE;
        if(blockinfo[type]&IS_ATLAS2){
            is2=TRUE;
            vert_array=verticesbg2;
            vert_c=v_idx2;
        }
        
        int rtype;
        int sideface=-1;
        int wshadow=80;
        
        int specialFace=-1;
        
        int gshadows[8]={235,178,191,223,  204, 159,127, 160,  };
        if((type>=TYPE_STONE_RAMP1&&type<=TYPE_ICE_SIDE4)){
            specialFace=angledFace[type-TYPE_STONE_RAMP1];
            rtype=type%4;
            if(type>=TYPE_STONE_SIDE1)rtype+=4;
            wshadow=gshadows[rtype];
            sideface=specialFace;
            
            
            //corners[0]=corners[1]=corners[2]=corners[3]=0;
            if((type>=TYPE_STONE_RAMP1&&type<=TYPE_ICE_RAMP4))
                top_shadow=( wshadow )/255.0f*top_shadow;
        }
        
        if(clr==0){
            if(type==TYPE_GRASS||type==TYPE_GRASS2||type==TYPE_GRASS3||type==TYPE_TNT||type==TYPE_FIREWORK||type==TYPE_BRICK||type==TYPE_VINE||type==TYPE_TRAMPOLINE||blockinfo[type]&IS_BLOCKTNT){
                coloring=TRUE;
            }
            if(blockinfo[type]&IS_BLOCKTNT){
                 extern  int blockTntMap[NUM_BLOCKS+1];
                for(int i=0;i<3;i++)
                    paint[i]=(float)blockColor[blockTntMap[type]][i]/255;
            }else{
            for(int i=0;i<3;i++)
                paint[i]=(float)blockColor[type][i]/255;
            }
        }
        const GLshort* cubeVertices=cubeShortVertices;
        const GLshort* cubeTextureCustom=cubeTexture;
        if(blockinfo[type]&IS_LIQUID){
            isLiquid=TRUE;
            int level=getLevel(type);
            int maxlevel=0;
            int maxleveld=0;
            for(int f=0;f<6;f++){
                if(!( isvisible&(1<<f) ) ){
                    if(f!=4&&f!=5){
                        int type2=getLandc((pbounds[0]+x+dx2[f]),(pbounds[2]+z+dz2[f]),(pbounds[1]+y+dy2[f]));
                        int level2=getLevel(type2);
                        if(level2>maxlevel){
                            maxlevel=level2;
                            maxleveld=f;
                        }
                    }
                    continue;
                }
                int sf=f*6*3;
                if(f!=4&&f!=5){
                    int type2=getLandc(pbounds[0]+x+dx2[f],(pbounds[2]+z+dz2[f]),(pbounds[1]+y+dy2[f]));
                    int level2=getLevel(type2);
                    if(level2<level){
                        if(getBaseType(type2)==getBaseType(type)){
                            
                            if(level2>maxlevel){
                                maxlevel=level2;
                                maxleveld=f;
                            }
                        }
                    }else level2=level;
                    
                    
                    
                    for(int v=0;v<6;v++){
                        int sv=sf+v*3;
                        
                        
                        
                        if(cubeShortVertices[sv+1]){
                            liquidCube[sv+1]=level;
                        }else{
                            liquidCube[sv+1]=level2;
                        }
                        
                        
                    }
                    
                }else{
                    for(int v=0;v<6;v++){
                        int sv=sf+v*3;
                        
                        
                        
                        if(cubeShortVertices[sv+1]){
                            liquidCube[sv+1]=level;
                        }
                        
                        
                    }  
                }
                
            }
            
            if(maxlevel==level)maxleveld=0;
            if(maxlevel<level)maxleveld=(2+maxleveld)%4;
            const GLshort* cubeVerticesTop;
            //  printg("maxleveld:%d",maxleveld);
            if(maxleveld==0){                
                cubeVerticesTop=side3Texture;
            }else if(maxleveld==1){               
                cubeVerticesTop=side1Texture;
            }else if(maxleveld==2){               
                cubeVerticesTop=side2Texture;
            }else if(maxleveld==3){               
                cubeVerticesTop=side4Texture;
            }
            
            for(int v=0;v<6;v++){
                for(int coord=0;coord<2;coord++){
                    
                    liquidTexture[5*6*2+v*2+coord]=cubeVerticesTop[5*6*2+v*2+coord];
                    
                }
            }
            
            cubeTextureCustom=liquidTexture;
            
            
        }else 
            if(type>=TYPE_STONE_SIDE1&&type<=TYPE_ICE_SIDE4){
                
                if(type%4==0){
                    cubeVertices=side1ShortVertices;
                    cubeTextureCustom=side1Texture;
                }else if((type+1)%4==0){
                    cubeVertices=side2ShortVertices;
                    cubeTextureCustom=side2Texture;
                }else if((type+2)%4==0){
                    cubeVertices=side3ShortVertices;
                    cubeTextureCustom=side3Texture;
                }else if((type+3)%4==0){
                    cubeVertices=side4ShortVertices;
                    cubeTextureCustom=side4Texture;
                }
                
            }else if(type>=TYPE_STONE_RAMP1&&type<=TYPE_ICE_RAMP4){
                if(type%4==0){
                    cubeVertices=ramp1ShortVertices;
                    cubeTextureCustom=ramp1Texture;
                }else if((type+1)%4==0){
                    cubeVertices=ramp2ShortVertices;
                    cubeTextureCustom=ramp2Texture;
                }else if((type+2)%4==0){
                    cubeVertices=ramp3ShortVertices;
                    cubeTextureCustom=ramp3Texture;
                }else if((type+3)%4==0){
                    cubeVertices=ramp4ShortVertices;
                    cubeTextureCustom=ramp4Texture;
                }
                
            }
        /*float lightm;
        if(type!=TYPE_LIGHTBOX){
            lightm=light[0];//lightsf[CC(x,z,y)];
        }else
            lightm=light[0];*/
        

        for(int f=0;f<6;f++){
            if(!( isvisible&(1<<f) ) )continue;
            int size=face_size[x*(CHUNK_SIZE*CHUNK_SIZE*6)+z*(CHUNK_SIZE*6)+y*6+f];
            int mergeAxis;
            if(f==5||f==4||f==0||f==1){
                mergeAxis=0;
            }else{
                mergeAxis=2;
            }
            
            
            if(!is2){
                if(f==specialFace){
                    vert_c=face_idx[6];
                    face_idx[6]+=6;
                }else{
                    vert_c=face_idx[f];
                    face_idx[f]+=6;  
                }
            }else{
                vert_c=face_idx2[f];
                face_idx2[f]+=6;  
                
            }
            
            int sf=f*6*3;
            
            int bf=blockTypeFaces[type][f];
            BOOL nosidecolor=FALSE;
            if(coloring){
                for(int i=0;i<3;i++)
                    paint[i]=1.0f;
                
                if(bf==TEX_GRASS_TOP||bf==TEX_GRASS_TOP2)
                {
                    
                    
                    for(int i=0;i<3;i++){
                        paint[i]=(float)(blockColor[TYPE_GRASS][i])/255;
                        if(paint[i]<0)paint[i]=0;
                    }
                }else if(bf==TEX_BLOCKTNT){
                    bf=TEX_BLOCKTNT;
                }
                else if(bf==TEX_GRASS_SIDE)
                    bf=TEX_GRASS_SIDE_COLOR;
                else if(bf==TEX_TNT_SIDE)
                    bf=TEX_TNT_SIDE_COLOR;
                else if(bf==TEX_TNT_TOP)
                    bf=TEX_TNT_TOP_COLOR;
                else if(bf==TEX_BRICK){
                    bf=TEX_BRICK_COLOR;
                }else if(blockinfo[type]&IS_BLOCKTNT){
                    extern  int blockTntMap[NUM_BLOCKS+1];
                    for(int i=0;i<3;i++){
                        paint[i]=(float)blockColor[ blockTntMap[type]][i]/255;
                    }
                } else if(bf==TEX_DIRT){
                    for(int i=0;i<3;i++)
                        paint[i]=(float)blockColor[TEX_DIRT][i]/255;
                } else if(!(blockinfo[type]&IS_LIQUID)&&type!=TYPE_VINE){
                    
                    
                    for(int i=0;i<3;i++){
                        paint[i]=(float)blockColor[type][i]/255;
                    }
                }
            }else{
                if(blockinfo[type]&IS_BLOCKTNT||type==TYPE_FIREWORK){
                    nosidecolor=TRUE;
                    
                }
            }
                       CGPoint tp;
            tp=res->getBlockTexShort(bf);
            
            
            
            for(int v=0;v<6;v++){
                int sv=sf+v*3;
               
                //if(f==0&&v==0)
               // printg("vert position1: (%d,%d,%d)\n",offsets[0], offsets[1], offsets[2]);
                for(int coord=0;coord<3;coord++){
                    
                    
                    if(isLiquid){
                        vert_array[vert_c].position[coord]=liquidCube[sv+coord]+4*offsets[coord];
                        
                    }else if(coord==mergeAxis){
                        
                        vert_array[vert_c].position[coord]=4*cubeVertices[sv+coord]*size+4*offsets[coord];  //crash count 1
                        
                    }
                    else{
                        vert_array[vert_c].position[coord]=4*cubeVertices[sv+coord]+4*offsets[coord];                    
                    }
                    int color;
                    if(type==TYPE_CLOUD&&f==4&&FALSE)
                        color=light[coord]*paint[coord]*180;
                    else if(f==5){
                        
                        color=light[coord]*paint[coord]*(float)cubeColors[f*3+coord];//*top_shadow;
                    }else if(type>=TYPE_STONE_SIDE1&&type<=TYPE_ICE_SIDE4&&sideface==f){
                        color=light[coord]*paint[coord]*wshadow;
                    }
                    else if(nosidecolor){
                        color=light[coord]*(float)cubeColors[f*3+coord];
                    }else
                        color=light[coord]*paint[coord]*(float)cubeColors[f*3+coord];
                    
                    //printg("WTFWTF\n");
                    if(burned){
                        color/=2.0f;
                    }
                    if(type==TYPE_LIGHTBOX||getBaseType(type)==TYPE_LAVA){
                        color=paint[coord]*255;
                    }
                    if(!nosidecolor&& color>paint[coord]*255) vert_array[vert_c].colors[coord]=paint[coord]*255;
                    else vert_array[vert_c].colors[coord]=color;
                }
                
                int st=f*6*2+v*2;
                
                vert_array[vert_c].texs[0]=cubeTextureCustom[st]*size;
                
                
                
                
                
                vert_array[vert_c].texs[1]=cubeTextureCustom[st+1]*tp.y+tp.x;
                if(!(blockinfo[type]&IS_ATLAS2)){
                    v_idx++;
                    if(vert_c>n_vertices){
                        printg("!! vert_c:%d  n_vertices:%d\n",vert_c,n_vertices);
                        if(f==specialFace){
                             printg("!! face_idx6:%d\n",face_idx[6]-6);
                           
                        }else{
                            printg("!! face_idx:%d\n",face_idx[f]-6);
                           
                        }
                       
                    }
                    vert_array[vert_c].colors[3]=0;
                }
                else{
                    v_idx2++;
                    
                    if(vert_c>n_vertices2){
                        printg("!!2 vert_c:%d  n_vertices2:%d\n",vert_c,n_vertices2);
                         printg("!!2 face_idx2:%d\n",face_idx2[f]-6);
                    }

                    if(blockinfo[type]&IS_WATER)vert_array[vert_c].colors[3]=145;
                    else
                        vert_array[vert_c].colors[3]=255;
                }
                
                vert_c++;
            }
        }
        
    }
    
    face_idx[0]=0;
    face_idx2[0]=0;
    for(int i=1;i<7;i++){       
        face_idx[i]=num_vertices[i-1]+face_idx[i-1];
        face_idx2[i]=num_vertices2[i-1]+face_idx2[i-1];
        
    }
    for(int i=0;i<7;i++)
        visibleFaces[i]=FALSE;
    vis_vertices=0;
   
    needsVBO=TRUE;
    
    
    return 1;
	
}
void TerrainChunk::prepareVBO(){
    rebuildCounter=0;
    if(clearOldVerticesOnly){
       // printg("clearing some old vertices\n");
       
        rtn_vertices=n_vertices=0;
        rtn_vertices2=n_vertices2=0;
        rtvis_vertices=vis_vertices=0;
        for(int i=0;i<7;i++){
            rtnum_vertices[i]=num_vertices[i]=0;
            rtface_idx[i]=face_idx[i]=0;
            rtnum_vertices2[i]=num_vertices2[i]=0;
            rtface_idx2[i]=face_idx2[i]=0;
            rtvisibleFaces[i]=visibleFaces[i]=0;
            
        }
        
        
        if(n_vertices){
            
          
            void* oldmem=rtindices;
           
            if(oldmem){
                free(oldmem);
                oldmem=NULL;
            }
            
            
        }
        
        if(vertexBuffer2)
            glDeleteBuffers(1, &vertexBuffer2);
        if(vertexBuffer)
            glDeleteBuffers(1, &vertexBuffer);    
        if(elementBuffer)
            glDeleteBuffers(1, &elementBuffer);
        vertexBuffer=0;
        vertexBuffer2=0;
        elementBuffer=0;
        
        if(verticesbg)
        free(verticesbg);
        if(verticesbg2)
        free(verticesbg2);
        verticesbg=NULL;
        verticesbg2=NULL;
        if(rtnum_objects>0){
            if(rtobjects)
            free(rtobjects);
            rtobjects=NULL;
            rtnum_objects=0;
            //printg("not freeing %d objects2\n",rtnum_objects);

        }
        needsVBO=FALSE;
       
    }
    if(!needsVBO){return;}
   
   	rtn_vertices=n_vertices;
  
    rtn_vertices2=n_vertices2;
    rtvis_vertices=vis_vertices;
    
    
    if(rtnum_objects>0){
        //printg("not freeing %d objects\n",rtnum_objects);
        if(rtobjects)
            free(rtobjects);
        rtobjects=NULL;
        
    }
    rtnum_objects=num_objects;
    rtobjects=objects;

    if(num_objects>0){
        //printg("vertice 1: (%d,%d,%d)\n",verticesbg[0].position[0],verticesbg[0].position[1],verticesbg[0].position[2]);
        }
        

    
    for(int i=0;i<7;i++){
        rtnum_vertices[i]=num_vertices[i];
        rtface_idx[i]=face_idx[i];
        rtnum_vertices2[i]=num_vertices2[i];
        rtface_idx2[i]=face_idx2[i];
        rtvisibleFaces[i]=visibleFaces[i];
        
    }
   
    
    if(n_vertices){
       
        indices=(unsigned short*)malloc(sizeof(unsigned short)*rtn_vertices);
        void* oldmem=rtindices;
        rtindices=indices;
        if(oldmem){
            free(oldmem);
            
        }
        
        
    }
    
    if(vertexBuffer2)
        glDeleteBuffers(1, &vertexBuffer2);
    if(vertexBuffer)
        glDeleteBuffers(1, &vertexBuffer);    
    if(elementBuffer)
        glDeleteBuffers(1, &elementBuffer);
    vertexBuffer=0;
    vertexBuffer2=0;
    elementBuffer=0;
    
    if(rtn_vertices){
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertexStructSmall)*rtn_vertices, verticesbg, GL_STATIC_DRAW);
        
        glGenBuffers(1,&elementBuffer);
               
    }
    
    if(rtn_vertices2){
        glGenBuffers(1, &vertexBuffer2);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer2);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertexStructSmall)*rtn_vertices2, verticesbg2, GL_STATIC_DRAW);
        
        
    } 
    if(verticesbg)
        free(verticesbg);
    if(verticesbg2)
        free(verticesbg2);
   
    verticesbg=NULL;
    verticesbg2=NULL;
    needsVBO=FALSE;
    
}

int TerrainChunk::getLand(int x,int z,int y){
	if(x<0||x>=CHUNK_SIZE||y<0||y>=CHUNK_SIZE||z<0||z>=CHUNK_SIZE)
	return getLandc(x+pbounds[0] ,z+pbounds[2] ,y+pbounds[1]);
	return pblocks[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y];
	
}

 /*- (int)getCustom:(int)x:(int)z:(int)y{
   int rx=x/2;
    int rz=z/2;
    int ry=y/2;
    
    if(blocks[(rx)*CHUNK_SIZE*CHUNK_SIZE+(rz)*CHUNK_SIZE+(ry)]!=TYPE_CUSTOM){
      //  printg("asking for custom, when block isn't custom\n");
         return blocks[(rx)*CHUNK_SIZE*CHUNK_SIZE+(rz)*CHUNK_SIZE+(ry)];
    }
    
    
     SmallBlock* sb=sblocks[rx*CHUNK_SIZE*CHUNK_SIZE+rz*CHUNK_SIZE+ry];
    if(sb==NULL){
        printg("asking for custom, can't find SmallBlock entry\n");
        return 0;
    }
    x-=rx*2;
    z-=rz*2;
    y-=ry*2;
    
   // printg("returning custom block: (%d,%d,%d)->%d\n",x,z,y,sb->blocks[x*2*2+z*2+y]);
    x=1-x;
    z=1-z;
    y=1-y;
    return sb->blocks[x*2*2+z*2+y];
 
    
} */

/*- (int)getCustomColor:(int)x:(int)z:(int)y{
    int rx=x/2;
    int rz=z/2;
    int ry=y/2;
    
    if(blocks[(rx)*CHUNK_SIZE*CHUNK_SIZE+(rz)*CHUNK_SIZE+(ry)]!=TYPE_CUSTOM){
        printg("asking for custom color, when block isn't custom\n");
        return 0;
    }
    
    SmallBlock* sb=sblocks[rx*CHUNK_SIZE*CHUNK_SIZE+rz*CHUNK_SIZE+ry];
    if(sb==NULL){
        printg("asking for custom color, can't find SmallBlock entry\n");
        return 0;
    }
    x-=rx*2;
    z-=rz*2;
    y-=ry*2;
    x=1-x;
    z=1-z;
    y=1-y;
    return sb->colors[x*2*2+z*2+y];
    
    
}
- (int)setCustom:(int)x:(int)z:(int)y:(int)type:(int)color{
    int rx=x/2;
    int rz=z/2;
    int ry=y/2;
    
    if(blocks[(rx)*CHUNK_SIZE*CHUNK_SIZE+(rz)*CHUNK_SIZE+(ry)]!=TYPE_CUSTOM){
        blocks[(rx)*CHUNK_SIZE*CHUNK_SIZE+(rz)*CHUNK_SIZE+(ry)]=TYPE_CUSTOM;
    }
    
    
    
    SmallBlock* sb=sblocks[rx*CHUNK_SIZE*CHUNK_SIZE+rz*CHUNK_SIZE+ry];
    if(sb==NULL){
        sblocks[rx*CHUNK_SIZE*CHUNK_SIZE+rz*CHUNK_SIZE+ry]=sb=malloc(sizeof(SmallBlock));
        memset(sb,0,sizeof(SmallBlock));
       // printg("allocated new custom\n");
    }
    x-=rx*2;
    z-=rz*2;
    y-=ry*2;
    x=1-x;
    z=1-z;
    y=1-y;
    sb->blocks[x*2*2+z*2+y]=type;
    sb->colors[x*2*2+z*2+y]=color;
    
    int solid=sb->blocks[0];
    int scolor=sb->colors[0];
    BOOL isSolid=TRUE;
    for(int i=1;i<8;i++){
        if(sb->blocks[i]!=solid||(solid!=TYPE_NONE&&sb->colors[i]!=scolor)){
            isSolid=FALSE;
            break;
        }    
        
        
        
        
        
        
    }
    if(isSolid){
        printg("custom became solid\n");
        
        blocks[(rx)*CHUNK_SIZE*CHUNK_SIZE+(rz)*CHUNK_SIZE+(ry)]=solid;
        colors[(rx)*CHUNK_SIZE*CHUNK_SIZE+(rz)*CHUNK_SIZE+(ry)]=scolor;
        return solid;
    }
    
    
    return -1;
 
    
}*/
void TerrainChunk::setLand(int x,int z,int y,int type){
   
	if(x<0||x>=CHUNK_SIZE||y<0||y>=CHUNK_SIZE||z<0||z>=CHUNK_SIZE){
		//NSLog(@"setting out of bounds chunks");
        ter->setLand(x+pbounds[0] ,z+pbounds[2] ,y+pbounds[1] ,type ,TRUE);
	}else{		
        
		pblocks[x*CHUNK_SIZE*CHUNK_SIZE+z*CHUNK_SIZE+y]=type;
		ter->setLand(x+pbounds[0] ,z+pbounds[2] ,y+pbounds[1] ,type ,FALSE);
	}

	
}


void TerrainChunk::unbuild(){

   
    clearMeshes();
    
    rtnum_objects=0;//disable objects for now
	rtn_vertices=n_vertices=0;
    rtn_vertices2=n_vertices2=0;
    rtvis_vertices=vis_vertices=0;
    for(int i=0;i<7;i++){
        rtnum_vertices[i]=num_vertices[i]=0;
        rtface_idx[i]=face_idx[i]=0;
        rtnum_vertices2[i]=num_vertices2[i]=0;
        rtface_idx2[i]=face_idx2[i]=0;
        rtvisibleFaces[i]=visibleFaces[i]=0;
        
    }
    
    
    
        void* oldmem=rtindices;
        rtindices=indices=0;
        if(oldmem)
            free(oldmem);
            
        
    
   
    
    
    
    if(vertexBuffer2)
        glDeleteBuffers(1, &vertexBuffer2);
    if(vertexBuffer)
        glDeleteBuffers(1, &vertexBuffer);
    
    if(elementBuffer)
        glDeleteBuffers(1, &elementBuffer);
    vertexBuffer=0;
    vertexBuffer2=0;
    elementBuffer=0;
}

TerrainChunk::~TerrainChunk(){
	
	
    clearMeshes();
    
    rtnum_objects=0;//disable objects for now
	rtn_vertices=n_vertices=0;
    rtn_vertices2=n_vertices2=0;
    rtvis_vertices=vis_vertices=0;
    for(int i=0;i<7;i++){
        rtnum_vertices[i]=num_vertices[i]=0;
        rtface_idx[i]=face_idx[i]=0;
        rtnum_vertices2[i]=num_vertices2[i]=0;
        rtface_idx2[i]=face_idx2[i]=0;
        rtvisibleFaces[i]=visibleFaces[i]=0;
        
    }
    for(int i=0;i<6;i++)
        pbounds[i]=0;
    
    
    void* oldmem=rtindices;
    rtindices=indices=0;
    if(oldmem)
        free(oldmem);
    
    
    
    
    
    
    
    if(vertexBuffer2)
        glDeleteBuffers(1, &vertexBuffer2);
    if(vertexBuffer)
        glDeleteBuffers(1, &vertexBuffer);
    
    if(elementBuffer)
        glDeleteBuffers(1, &elementBuffer);
    vertexBuffer=0;
    vertexBuffer2=0;
    elementBuffer=0;
	
}

void TerrainChunk::clearMeshes(){
   // printg("vb %d, %d, %d",vertexBuffer,vertexBuffer2,elementBuffer);
    
    num_objects=0;
    objects=NULL;
    if(verticesbg)
    free(verticesbg);
    if(verticesbg2)
    free(verticesbg2);
    verticesbg=NULL;
    verticesbg2=NULL;
    
    
   
    /*for(int x=0;x<CHUNK_SIZE;x++){
        for(int y=0;y<CHUNK_SIZE;y++){
            for(int z=0;z<CHUNK_SIZE;z++){
                if(sblocks[x*(CHUNK_SIZE2)+z*CHUNK_SIZE+y]!=NULL){
                    free(sblocks[x*(CHUNK_SIZE2)+z*CHUNK_SIZE+y]);
                    sblocks[x*(CHUNK_SIZE2)+z*CHUNK_SIZE+y]=NULL;
                }
            }
        }
    }*/
	n_vertices=n_vertices2=0;
}


int TerrainChunk::render(){
    
	if(rtn_vertices==0)
        return 0;
   
    /*if(isTesting==0){
        
        glBeginQueryEXT( GL_ANY_SAMPLES_PASSED_EXT,query);
        isTesting=1;
    }else if(isTesting==2){
        GLint res;
        glGetQueryObjectivEXT(query, GL_QUERY_RESULT_AVAILABLE_EXT,&res);
        NSLog(@"av result for %d: %d",(int)query,res); 
        if(res){
            
            glGetQueryObjectivEXT(query, GL_QUERY_RESULT_EXT,&res); 
            //GL_INVALID_OPERATION
            isTesting=-60+n_vertices%10;
            NSLog(@"result for %d: %d",(int)query,res);    
        }
    }else if(isTesting<0){
        isTesting++;
    }*/
   
	glPushMatrix();
  //  if(World::getWorld->hud.heartbeat)
   // printg("rtbounds %f  proposedoffset %d\n",rbounds[0],World::getWorld->fm.chunkOffsetX*CHUNK_SIZE);
    //glTranslatef((rtbounds[0])*4, rtbounds[1]*4, (rtbounds[2])*4);
	glTranslatef((pbounds[0]-World::getWorld->fm->chunkOffsetX*CHUNK_SIZE)*4, pbounds[1]*4, (pbounds[2]-World::getWorld->fm->chunkOffsetZ*CHUNK_SIZE)*4);
    
    
	/*offsets[0]=BLOCK_SIZE*x+rbounds[0];
	offsets[1]=BLOCK_SIZE*y+rbounds[1];
	offsets[2]=BLOCK_SIZE*z+rbounds[2];*/
	
	
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	
	glVertexPointer(3, GL_SHORT, sizeof(vertexStructSmall), (void*)offsetof(vertexStructSmall,position));
	glTexCoordPointer(2, GL_SHORT,  sizeof(vertexStructSmall),  (void*)offsetof(vertexStructSmall,texs));
	glColorPointer(	4, GL_UNSIGNED_BYTE, sizeof(vertexStructSmall), (void*)offsetof(vertexStructSmall,colors));
	
    //glDrawArrays(GL_TRIANGLES, 0, n_vertices);

    Camera* cam=World::getWorld->cam;
   	/*0,0,1, //front face
	
		
	0,0,-1, //back face
	
	
	-1,0,0, //left face
	
	
	1,0,0, //right face
		
	0,-1,0, //bot face
		
	0,1,0, //top face*/
    bool rebuildIndices=FALSE;
    bool curVis[7];
    curVis[5]=cam->py>=pbounds[1]&&rtnum_vertices[5]!=0;
    
    curVis[1]=cam->pz>=pbounds[2]&&rtnum_vertices[1]!=0;
     
    
    curVis[0]=cam->pz<=pbounds[5]&&rtnum_vertices[0]!=0;
   
    
    
    
    curVis[3]=cam->px>=pbounds[0]&&rtnum_vertices[3]!=0;
    
    
    curVis[2]=cam->px<=pbounds[3]&&rtnum_vertices[2]!=0;
    
    
    curVis[4]=cam->py<=pbounds[4]&&rtnum_vertices[4]!=0;
    
    
    curVis[6]=rtnum_vertices[6]!=0;
    
    for(int i=0;i<7;i++){
        if(curVis[i]!=rtvisibleFaces[i]){
            rtvisibleFaces[i]=curVis[i];
            rebuildIndices=TRUE;
        }
    }
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,elementBuffer);
    //rebuildIndices=TRUE;
     int n=0;
    if(rebuildIndices){
       // printg("rebuilding");
       for(int i=0;i<7;i++){ 
           if(rtvisibleFaces[i]){
               if(n+rtnum_vertices[i]>=INDICES_MAX)
                   continue;
           memcpy((char*)(rtindices+n),
                  (char*)(allIndices+rtface_idx[i]),
                  rtnum_vertices[i]*sizeof(unsigned short));
           n+=rtnum_vertices[i];
             
           }
           
       }
        
       // if(n>0&&n<=rtvis_vertices)
       //     glBufferSubData(GL_ELEMENT_ARRAY_BUFFER,0,sizeof(unsigned short)*n,rtindices);
        //else
            glBufferData(GL_ELEMENT_ARRAY_BUFFER,sizeof(unsigned short)*n,rtindices,GL_STATIC_DRAW);
        rtvis_vertices=n;
        
    }
    int totalvert=0;         
    for(int i=0;i<7;i++){
        
        totalvert+=rtnum_vertices[i];
    }
    if(totalvert>rtn_vertices||rtface_idx[6]+rtnum_vertices[6]>rtn_vertices||rtvis_vertices>rtn_vertices){
        printg("Great\n");
    }
    if(rtvis_vertices!=0){
    
       /* if(modified==TRUE){
            glDisable(GL_TEXTURE_2D);
        }*/
        glDrawElements(GL_TRIANGLES,rtvis_vertices,GL_UNSIGNED_SHORT,0);
        //if(modified==TRUE){
        //    glEnable(GL_TEXTURE_2D);
        //}
    }
   
   
    
    //glDrawArrays(GL_TRIANGLES, 0, n_vertices);	
    glPopMatrix();
    
   //glTranslatef(-(rtbounds[0]-World::getWorld->fm.chunkOffsetX*CHUNK_SIZE)*4, -rtbounds[1]*4, -(rtbounds[2]-World::getWorld->fm.chunkOffsetZ*CHUNK_SIZE)*4);
	return rtvis_vertices;

	

	
}
void TerrainChunk::render2(){
   
    glPushMatrix();
	glTranslatef((pbounds[0]-World::getWorld->fm->chunkOffsetX*CHUNK_SIZE)*4, pbounds[1]*4, (pbounds[2]-World::getWorld->fm->chunkOffsetZ*CHUNK_SIZE)*4);
	/*offsets[0]=BLOCK_SIZE*x+rbounds[0];
     offsets[1]=BLOCK_SIZE*y+rbounds[1];
     offsets[2]=BLOCK_SIZE*z+rbounds[2];*/
	
	
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer2);
	
	glVertexPointer(3, GL_SHORT, sizeof(vertexStructSmall), (void*)offsetof(vertexStructSmall,position));
	glTexCoordPointer(2, GL_SHORT,  sizeof(vertexStructSmall),  (void*)offsetof(vertexStructSmall,texs));
	glColorPointer(	4, GL_UNSIGNED_BYTE, sizeof(vertexStructSmall), (void*)offsetof(vertexStructSmall,colors));
	
     Camera* cam=World::getWorld->cam;
	
    if(cam->py>=pbounds[1]&&rtnum_vertices2[5]!=0)
        glDrawArrays(GL_TRIANGLES, rtface_idx2[5], rtnum_vertices2[5]);
    
    if(cam->pz>=pbounds[2]&&rtnum_vertices2[1]!=0)
        glDrawArrays(GL_TRIANGLES, rtface_idx2[1], rtnum_vertices2[1]);
    
    if(cam->pz<=pbounds[5]&&rtnum_vertices2[0]!=0)
        glDrawArrays(GL_TRIANGLES, rtface_idx2[0], rtnum_vertices2[0]);
    
    
    
    if(cam->px>=pbounds[0]&&rtnum_vertices2[3]!=0)
        glDrawArrays(GL_TRIANGLES, rtface_idx2[3], rtnum_vertices2[3]);
    
    if(cam->px<=pbounds[3]&&rtnum_vertices2[2]!=0)
        glDrawArrays(GL_TRIANGLES, rtface_idx2[2], rtnum_vertices2[2]);
    
    if(cam->py<=pbounds[4]&&rtnum_vertices2[4]!=0)
        glDrawArrays(GL_TRIANGLES, rtface_idx2[4], rtnum_vertices2[4]);

	glPopMatrix();
	
}


